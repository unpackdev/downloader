// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC677.sol";
import "./ERC777Permit.sol";
import "./Ownable.sol";
import "./ERC777.sol";

contract XRUNE is ERC777, ERC777Permit, ERC677, Ownable {
    uint256 public constant ERA_SECONDS = 86400;
    uint256 public constant MAX_SUPPLY = 1000000000 ether;
    uint256 public nextEra = 1622433600; // 2021-05-31
    uint256 public curve = 1024;
    bool public emitting = false;
    address public reserve = address(0);

    event NewEra(uint256 time, uint256 emission);

    constructor(address owner)
        public
        ERC777("XRUNE Token", "XRUNE", new address[](0))
        ERC777Permit("XRUNE")
        Ownable(owner)
    {
        _mint(owner, MAX_SUPPLY / 2, "", "");
    }

    function setCurve(uint256 _curve) public onlyOwner {
        require(
            _curve > 0 && _curve < 10000,
            "curve needs to be between 0 and 10000"
        );
        curve = _curve;
    }

    function toggleEmitting() public onlyOwner {
        emitting = !emitting;
    }

    function setReserve(address _reserve) public onlyOwner {
        reserve = _reserve;
    }

    function setNextEra(uint256 next) public onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        require(
            next > nextEra && next > block.timestamp,
            "next era needs to be in the future"
        );
        nextEra = next;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, amount);
        require(to != address(this), "!self");
        dailyEmit();
    }

    function dailyEmit() public {
        // solhint-disable-next-line not-rely-on-time
        if ((block.timestamp >= nextEra) && emitting && reserve != address(0)) {
            uint256 _emission = dailyEmission();
            emit NewEra(nextEra, _emission);
            nextEra = nextEra + ERA_SECONDS;
            _mint(reserve, _emission, "", "");
        }
    }

    function dailyEmission() public view returns (uint256) {
        return (MAX_SUPPLY - totalSupply()) / curve;
    }
}
