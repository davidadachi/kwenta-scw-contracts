// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/* solhint-disable no-empty-blocks */

import {IAuthorizationModule} from
    "src/biconomy/interfaces/IAuthorizationModule.sol";
import {ISignatureValidator} from
    "src/biconomy/interfaces/ISignatureValidator.sol";

contract AuthorizationModulesConstants {
    uint256 internal constant VALIDATION_SUCCESS = 0;
    uint256 internal constant SIG_VALIDATION_FAILED = 1;
}

abstract contract BaseAuthorizationModule is
    IAuthorizationModule,
    ISignatureValidator,
    AuthorizationModulesConstants
{}
