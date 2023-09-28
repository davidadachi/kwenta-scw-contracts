// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {console2} from "lib/forge-std/src/console2.sol";
import {
    SMv2SessionValidationModule,
    SMv3SessionValidationModule,
    OptimismGoerliParameters,
    OptimismParameters,
    Setup
} from "script/Deploy.s.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract Bootstrap is Test {
    using console2 for *;

    SMv2SessionValidationModule public smv2SessionValidationModule;
    SMv3SessionValidationModule public smv3SessionValidationModule;

    function initializeOptimismGoerli() public {
        BootstrapOptimismGoerli bootstrap = new BootstrapOptimismGoerli();
        (
            address smv2SessionValidationModuleAddress,
            address smv3SessionValidationModuleAddress
        ) = bootstrap.init();

        smv2SessionValidationModule =
            SMv2SessionValidationModule(smv2SessionValidationModuleAddress);
        smv3SessionValidationModule =
            SMv3SessionValidationModule(smv3SessionValidationModuleAddress);
    }

    /// @dev add other networks here as needed (ex: Base, BaseGoerli)
}

contract BootstrapOptimismGoerli is Setup, OptimismGoerliParameters {
    function init() public returns (address, address) {
        (
            address smv2SessionValidationModuleAddress,
            address smv3SessionValidationModuleAddress
        ) = Setup.deploySystem();

        return (
            smv2SessionValidationModuleAddress,
            smv3SessionValidationModuleAddress
        );
    }
}

// add other networks here as needed (ex: Base, BaseGoerli)
