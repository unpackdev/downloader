// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IOwnable.sol";
import "./IQuest.sol";

// solhint-disable-next-line no-empty-blocks
interface IQuestOwnable is IQuest, IOwnable {}
