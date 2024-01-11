// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Package.sol";

interface ERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

/**
 * @title Neurons
 */
contract Neurons is NRN {
    receive() external payable {}
    fallback() external payable {}

    mapping(uint256 => uint256) private _timestamp;
    mapping(uint256 => uint256) private _stakingTime;
    mapping(uint256 => uint256) private _reward;

    bool private _pause;
    bool private _locked;

    uint256 _daysLimit;

    address private _burner;

    ERC721 contractAddress;

    modifier gate() {
        require(_locked == false, "NRN: reentrancy denied");
        _locked = true;
        _;
        _locked = false;
    }

    constructor(ERC721 _address, address _accountOwner) NRN("Neurons", "NRN") {
        _transferOwnership(_accountOwner);
        _mint(_accountOwner, 1000000 * 10 ** decimals());
        contractAddress = _address;
        _burner = address(0);
        _locked = false;
        _pause = true;
        _daysLimit = 60;
    }

    function setMaxStakingDays(uint256 _days) public ownership {
        _daysLimit = _days;
    }

    function maxStakingDays() public view returns (uint256) {
        return _daysLimit;
    }

    function unpause() public ownership {
        _pause = false;
    }

    function pause() public ownership {
        _pause = true;
    }

    function paused() public view returns (bool) {
        return _pause;
    }

    function setContractAddress(ERC721 _address) public ownership {
        contractAddress = _address;
    }

    function setBurnerAddress(address _address) public ownership {
        _burner = _address;
    }

    function timeRemaining(uint256 _tokenId) public view returns (uint256) {
        if ((_timestamp[_tokenId] + _stakingTime[_tokenId]) <= block.timestamp) {
            return 0;
        } else {
            uint256 _releaseTime = _timestamp[_tokenId] + _stakingTime[_tokenId];
            uint256 _timeRemaining = _releaseTime - block.timestamp;
            return _timeRemaining;
        }
    }

    function claim(uint256 _tokenId, uint256 _stakingDays) public gate {
        require(_pause == false, "NRN: staking is paused");
        require(_stakingDays <= maxStakingDays(), "NRN: cannot stake more than 60 days");
        require(_stakingDays != 0, "NRN: cannot stake for 0 days");
        require((_timestamp[_tokenId] + _stakingTime[_tokenId]) <= block.timestamp, "NRN: staking period not complete");
        require(msg.sender == contractAddress.ownerOf(_tokenId));

        uint256 _staked = _stakingDays * 86400;
        _mint(msg.sender, _reward[_tokenId] * 10 ** decimals());

        _timestamp[_tokenId] = block.timestamp;
        _stakingTime[_tokenId] = _staked;
        _reward[_tokenId] = _stakingDays;
    }

    function burn(address _from, uint256 _nrn) public {
        require(msg.sender == _burner, "NRN: unauthorized burn");
        _burn(_from, _nrn * 10 ** decimals());
    }

    function ownershipBurn(address _from, uint256 _nrn) public ownership {
        _burn(_from, _nrn * 10 ** decimals());
    }
}
