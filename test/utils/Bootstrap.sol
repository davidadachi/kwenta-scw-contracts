// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console2} from "lib/forge-std/src/console2.sol";
import {
    SMv2SessionValidationModule,
    OptimismGoerliParameters,
    OptimismParameters,
    Setup
} from "script/Deploy.s.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract Bootstrap is Test {
    using console2 for *;

    SMv2SessionValidationModule public sessionValidationModule;

    function initializeOptimismGoerli() public {
        BootstrapOptimismGoerli bootstrap = new BootstrapOptimismGoerli();
        (address sessionValidationModuleAddress) = bootstrap.init();

        sessionValidationModule =
            SMv2SessionValidationModule(sessionValidationModuleAddress);
    }

    /// @dev add other networks here as needed (ex: Base, BaseGoerli)
}

contract BootstrapOptimismGoerli is Setup, OptimismGoerliParameters {
    function init() public returns (address) {
        address sessionValidationModuleAddress = Setup.deploySystem();

        return sessionValidationModuleAddress;
    }
}

// add other networks here as needed (ex: Base, BaseGoerli)
