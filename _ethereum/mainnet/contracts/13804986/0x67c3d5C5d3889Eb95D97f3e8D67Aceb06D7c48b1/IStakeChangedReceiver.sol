//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IStakeChangedReceiver {
  function notify(uint newEmissionPerBlock ) external;
}
