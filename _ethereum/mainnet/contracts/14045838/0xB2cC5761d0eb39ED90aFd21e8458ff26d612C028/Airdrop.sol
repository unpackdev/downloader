//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

import "./IAirdrop.sol";
import "./IEdition.sol";

contract Airdrop is IAirdrop {

    using SafeMath for uint256;

    IEdition public immutable nftToken;
    address public donationAddress;
    mapping(uint16 => uint8) public claimStatus;
    address public owner;
    
    constructor(address _nftToken) {
        nftToken = IEdition(_nftToken);
        owner = msg.sender;
    }
    
    function setDonationAddress(address _donationAddress) external onlyOwner {
        donationAddress = _donationAddress;
    }
    
    function updateOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function claimAirdrop(uint16[] calldata _tokenIds) override external {
        uint256 balance;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            uint16 tokenId = _tokenIds[i];
            require(nftToken.ownerOf(tokenId) == msg.sender, "ERC721: not owner of token");
            if (!isTokenUsed(tokenId)) {
                if (nftToken.tokenToEdition(tokenId) == 184) {
                    balance = balance.add(100);
                    setTokenUsed(tokenId);
                } else if (nftToken.tokenToEdition(tokenId) == 186) {
                    balance = balance.add(1000);
                    setTokenUsed(tokenId);
                }
            }
        }
        emit AirdropClaim(msg.sender, balance.mul(1e18));
    }
    
    function donate(uint16[] calldata _tokenIds) override external {
        uint256 balance;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            uint16 tokenId = _tokenIds[i];
            require(nftToken.ownerOf(tokenId) == msg.sender, "ERC721: not owner of token");
            if (!isTokenUsed(tokenId)) {
                if (nftToken.tokenToEdition(tokenId) == 184) {
                    balance = balance.add(100);
                    setTokenUsed(tokenId);
                } else if (nftToken.tokenToEdition(tokenId) == 186) {
                    balance = balance.add(1000);
                    setTokenUsed(tokenId);
                }
            }
        }
        emit AirdropClaim(donationAddress, balance.mul(1e18));
        
    }

    function isTokenUsed(uint16 _position) public view override returns (bool) {
        uint16 byteNum = uint16(_position / 8);
        uint16 bitPos = uint8(_position - byteNum * 8);
        if (claimStatus[byteNum] == 0) return false;
        return claimStatus[byteNum] & (0x01 * 2 ** bitPos) != 0;
    }

    function setTokenUsed(uint16 _position) internal {
        uint16 byteNum = uint16(_position / 8);
        uint16 bitPos = uint8(_position - byteNum * 8);
        claimStatus[byteNum] = uint8(claimStatus[byteNum] | (2 ** bitPos));
    }

    function getUsedTokenData(uint8 _page, uint16 _perPage)
    public
    view
    returns (uint8[] memory)
    {
        _perPage = _perPage / 8;
        uint16 i = _perPage * _page;
        uint16 max = i + (_perPage);
        uint16 j = 0;
        uint8[] memory retValues;

        assembly {
            mstore(retValues, _perPage)
        }

        while (i < max) {
            retValues[j] = claimStatus[i];
            j++;
            i++;
        }

        assembly {
        // move pointer to freespace otherwise return calldata gets messed up
            mstore(0x40, msize())
        }
        return retValues;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

}
