// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DecentralizedStableCoinTest is Test {
    address deployer = makeAddr("deployer");
    address owner = makeAddr("owner");
    address user = makeAddr("user");

    function testZeroAddressCantMint() external {
        vm.startBroadcast(deployer);
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        dsc.transferOwnership(owner);
        vm.stopBroadcast();
        vm.prank(owner);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__NotZeroAddress.selector);
        dsc.mint(address(0), 1 ether);
    }

    function testCantMintZeroToken() external {
        vm.startBroadcast(deployer);
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        dsc.transferOwnership(owner);
        vm.stopBroadcast();
        vm.prank(owner);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__MustBeMoreThanZero.selector);
        dsc.mint(address(owner), 0 ether);
    }

    function testCantBurnMoreTokenThanBalance() external {
        vm.startBroadcast(deployer);
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        dsc.transferOwnership(owner);
        vm.stopBroadcast();
        vm.prank(owner);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__BurnAmountExceedsBalance.selector);
        dsc.burn(1);
    }

    function testCantBurnZeroToken() external {
        vm.startBroadcast(deployer);
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        dsc.transferOwnership(owner);
        vm.stopBroadcast();
        vm.prank(owner);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__MustBeMoreThanZero.selector);
        dsc.burn(0 ether);
    }
}
