// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20MintBurnable.sol";
import "./IERC721Mintable.sol";

contract Fundraiser {
    mapping(address => uint256) public contributed;
    uint256[] public tokensPerWei;
    IERC20MintBurnable public immutable token;
    IERC721Mintable public immutable nft;
    address payable public immutable fundStorage;
    uint32 public immutable start;
    uint32[] public end;
    uint256 public immutable minWeiPerAccount;
    uint256 public immutable maxWeiPerAccount;

    error LessThanMinPerAccount();
    error SurpassMaxPerAccount();
    error FundStorageReverted();
    error NotDuringFundraisingPeriod();
    error NoFundsAttached();
    error FundraiserNotOverYet();

    constructor(
        uint256[] memory _tokensPerWei,
        IERC20MintBurnable _token,
        IERC721Mintable _nft,
        address payable _fundStorage,
        uint32 _start,
        uint32[] memory _end,
        uint256 _minWeiPerAccount,
        uint256 _maxWeiPerAccount
    ) {
        tokensPerWei = _tokensPerWei;
        token = _token;
        nft = _nft;
        fundStorage = _fundStorage;
        start = _start;
        end = _end;
        minWeiPerAccount = _minWeiPerAccount;
        maxWeiPerAccount = _maxWeiPerAccount;
    }

    fallback() external payable {
        _fundraise();
    }

    receive() external payable {
        _fundraise();
    }

    function _currentTokensPerWei() public view returns (uint256) {
        if (block.timestamp < start) {
            revert NotDuringFundraisingPeriod();
        }

        for (uint i; i < end.length; ) {
            if (block.timestamp < end[i]) {
                return tokensPerWei[i];
            }

            unchecked {
                ++i;
            }
        }

        revert NotDuringFundraisingPeriod();
    }

    function _fundraise() internal {
        if (msg.value == 0) {
            revert NoFundsAttached();
        }

        uint256 personalContribution = contributed[msg.sender] + msg.value;
        if (personalContribution < minWeiPerAccount) {
            revert LessThanMinPerAccount();
        }
        if (personalContribution > maxWeiPerAccount) {
            revert SurpassMaxPerAccount();
        }

        token.transfer(msg.sender, msg.value * _currentTokensPerWei());
        if (personalContribution == maxWeiPerAccount) {
            nft.mint(msg.sender);
        }

        contributed[msg.sender] = personalContribution;
    }

    function fundsToStorage() external {
        if (block.timestamp < end[end.length - 1]) {
            revert FundraiserNotOverYet();
        }

        // Send raised funds to treasury
        (bool succes, ) = fundStorage.call{value: address(this).balance}("");
        if (!succes) {
            revert FundStorageReverted();
        }

        // Burn remaining tokens
        token.burn(token.balanceOf(address(this)));
    }
}
