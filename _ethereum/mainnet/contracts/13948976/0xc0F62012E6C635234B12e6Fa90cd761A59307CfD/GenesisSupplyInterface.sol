//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Supply ABI needed from Genesis Contract
contract DeployedSupply {
    function setIsRevealed(bool _isRevealed) external {}

    function currentIndex() public view returns (uint256 index) {}

    function reservedGodsCurrentIndexAndSupply()
        public
        view
        returns (uint256 index, uint256 supply)
    {}

    function mint(uint256 count)
        public
        returns (uint256 startIndex, uint256 endIndex)
    {}

    function mintReservedGods(uint256 count) public {}
}
