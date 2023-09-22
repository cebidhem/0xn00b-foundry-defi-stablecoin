// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    address user = makeAddr("user");
    // NetworkConfig public activeNetworkConfig;

    // struct NetworkConfig {
    //     address wethUsdPriceFeed;
    //     address wbtcUsdPriceFeed;
    //     address weth;
    //     address wbtc;
    //     uint256 deployerKey;
    // }

    function testAnvilNetworkConfig() public {
        HelperConfig helper = new HelperConfig();
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            helper.activeNetworkConfig();

        assertEq(wethUsdPriceFeed, address(0x90193C961A926261B756D1E5bb255e67ff9498A1));
        assertEq(wbtcUsdPriceFeed, address(0xBb2180ebd78ce97360503434eD37fcf4a1Df61c3));
        assertEq(weth, address(0xA8452Ec99ce0C64f20701dB7dD3abDb607c00496));
        assertEq(wbtc, address(0xDB8cFf278adCCF9E9b5da745B44E754fC4EE3C76));
        assertEq(deployerKey, 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        assertEq(address(this).balance, 1000e8);
    }
}
