// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "./IAspenFeatures.sol";
import "./IAspenVersioned.sol";
import "./IMulticallable.sol";
import "./IAgreementsNotary.sol";

interface IAspenAgreementsNotaryV0 is IAspenFeaturesV1, IAspenVersionedV2, IMulticallableV0, IAgreementsNotaryV0 {}
