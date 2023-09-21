// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DeployDSCTest is Test {
    DSCEngine engine;
    DecentralizedStableCoin dsc;
    HelperConfig helper;

    function testDeployDSC() public {
        DeployDSC deploy = new DeployDSC();
        (dsc, engine, helper) = deploy.run();
        console.log("DeployDSC deployed at %s", address(engine));
        assertEq(address(engine), address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512));
    }
}
