pragma solidity >=0.7.0 <0.8.0;

import "./Common.sol";

interface IVault is IERC20 {
    function withdraw() external;

    function rewards() external view returns (address);
}
