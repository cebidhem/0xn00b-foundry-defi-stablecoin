// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;

    address user = makeAddr("user");
    address liquidator = makeAddr("liquidator");
    uint256 public constant AMOUNT_COLLATERAL = 50 ether;
    uint256 public constant AMOUNT_MINT_DSC = 1 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (ethUsdPriceFeed,, weth,,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(user, STARTING_ERC20_BALANCE);
    }

    modifier depositedCollateral() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    modifier depositedCollateralAndMintedDsc() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, AMOUNT_MINT_DSC);
        vm.stopPrank();
        _;
    }

    //////////////
    // constructor tests
    //////////////
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);
        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    //////////////
    // price tests
    //////////////

    function testGetUsdPrice() public {
        uint256 ethAmount = 15e18;
        uint256 expectedUsdPrice = 30000e18;
        uint256 actualUsdPrice = engine.getUsdValue(weth, ethAmount);
        assertEq(actualUsdPrice, expectedUsdPrice);
    }

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 30000e18;
        uint256 expectedWeth = 15e18;
        uint256 actualWeth = engine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(actualWeth, expectedWeth);
    }

    //////////////
    // depositCollateral tests
    //////////////

    function testRevertIfCollateralIsZero() public {
        vm.prank(user);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__MoreThanZero.selector);
        engine.depositCollateral(weth, 0);
    }

    function testRevertIfCollateralIsNotAllowed() public {
        vm.prank(user);
        ERC20Mock wblahMock = new ERC20Mock("Wrapped Blah", "WBLAH", user, AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__TokenNotAllowed.selector);
        engine.depositCollateral(address(wblahMock), AMOUNT_COLLATERAL);
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInfo(user);
        uint256 expectedTotalDscMinted = 0;
        console.log("collateralValueInUsd", collateralValueInUsd);
        console.log("totalDscMinted", totalDscMinted);
        uint256 expectedDepositAmount = engine.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }

    //////////////
    // mint tests
    //////////////

    function testMintDsc() public depositedCollateral {
        vm.prank(user);
        engine.mintDsc(AMOUNT_MINT_DSC);
        (uint256 totalDscMinted,) = engine.getAccountInfo(user);
        uint256 expectedTotalDscMinted = AMOUNT_MINT_DSC;
        assertEq(totalDscMinted, expectedTotalDscMinted);
    }

    //////////////
    // deposit/mint tests
    //////////////

    function testDepositAndMint() public depositedCollateralAndMintedDsc {
        vm.prank(user);
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInfo(user);
        uint256 expectedTotalDscMinted = AMOUNT_MINT_DSC;
        uint256 expectedDepositAmount = engine.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }

    //////////////
    // burn tests
    //////////////

    function testCanBurnDsc() public depositedCollateralAndMintedDsc {
        vm.startPrank(user);
        dsc.approve(address(engine), AMOUNT_MINT_DSC);
        engine.burnDsc(AMOUNT_MINT_DSC);
        vm.stopPrank();

        uint256 userBalance = dsc.balanceOf(user);
        assertEq(userBalance, 0);
    }

    //////////////
    // redeem tests
    //////////////

    function testCanRedeemCollateral() public depositedCollateral {
        vm.startPrank(user);
        engine.redeemCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();

        uint256 userBalance = user.balance;
        assertEq(userBalance, 0);
    }

    //////////////
    // burn/redeem tests
    //////////////

    function testCanBurnDscAndRedeemCollateral() public depositedCollateralAndMintedDsc {
        vm.startPrank(user);
        dsc.approve(address(engine), AMOUNT_MINT_DSC);
        engine.redeemDSCAndWithdrawCollateral(weth, AMOUNT_COLLATERAL, AMOUNT_MINT_DSC);
        vm.stopPrank();

        uint256 dscuserBalance = dsc.balanceOf(user);
        assertEq(dscuserBalance, 0);
        uint256 userBalance = ERC20Mock(weth).balanceOf(user);
        assertEq(userBalance, STARTING_ERC20_BALANCE);
    }

    //////////////
    // liquidate tests
    //////////////

    function testCantLiquidateHealthFactorOK() public depositedCollateralAndMintedDsc {
        vm.startPrank(liquidator);
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorOK.selector);
        engine.liquidate(weth, user, AMOUNT_MINT_DSC);
        vm.stopPrank();
    }

    // NOT WORKING
    // function testCanLiquidate() public depositedCollateralAndMintedDsc {
    //     vm.startPrank(liquidator);
    //     ERC20Mock(weth).mint(liquidator, STARTING_ERC20_BALANCE);
    //     ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
    //     engine.depositCollateral(weth, AMOUNT_COLLATERAL);
    //     engine.liquidate(weth, user, AMOUNT_MINT_DSC);
    //     vm.stopPrank();

    //     uint256 dscuserBalance = dsc.balanceOf(user);
    //     assertEq(dscuserBalance, 0);
    //     uint256 userBalance = ERC20Mock(weth).balanceOf(user);
    //     assertEq(userBalance, STARTING_ERC20_BALANCE);
    // }
}
