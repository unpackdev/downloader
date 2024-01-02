// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// @title: Vaulted
// @creator: Isaac Wright

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                      VAULTED BY DRIFTERSHOOTS                        //
//                                                                      //
//                                                                      //
//  Vaulted was created in the spirit of communion between the artist,  //
//      the observer and time. It is a commitment to the patience,      //
//   perseverance and uncertainty that shapes the life and work of the  //
//   artist. As time works on us all as it inevitably does, the shape   //
//               and significance of art changes as well.               //
//      Art is meant to be treasured, and observed with discretion,     //
//          care and patience. Art is demands to be vaulted.            //
//                                                                      //
//                                                                      //
//                                                                      //
//                ██████████████████████████████████████                //
//              ████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████              //
//            ████▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒████            //
//            ██▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒██            //
//          ████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████          //
//          ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ░░░░░░  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██          //
//          ████████████████████  ░░░░░░  ████████████████████          //
//          ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ░░░░░░  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██          //
//          ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ░░██░░  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██          //
//          ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░██░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██          //
//          ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██          //
//          ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██          //
//          ██░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░██          //
//          ██░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░██          //
//          ██░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░██          //
//          ██████████████████████████████████████████████████          //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////

import "./AdminControl.sol";

import "./IERC721.sol";
import "./ERC165.sol";
import "./ERC165Checker.sol";

import "./Strings.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint _id, bytes calldata _data) external returns(bytes4);
}

contract Vaulted is ERC721TokenReceiver, AdminControl, ReentrancyGuard {

    using Strings for uint;
    using Address for string;

    // Default vaulting multiplier is 1.5x for locking in for 1-4 years, 2.5x for 5-9 years, and 4x for 10 years.
    uint[11] public multiplier = [100, 150, 150, 150, 150, 250, 250, 250, 250, 250, 400];

    // struct to store information about a single vaulted token
    struct Vaulting {
        uint startDT;  // the start date-time of the vaulting
        address owner; // the owner of the vaulted token
        uint unlockDT; // the date-time when the token can be unvaulted
        uint multiplier; // the multiplier applied to the token
        uint priorScore; // the prior recorded score before revaulting
    }

    struct TokenAndAddress {
        address contractAddress;
        uint tokenId;
    }

    mapping(address => mapping(uint => Vaulting)) public contractTokenIdToVaulting;
    mapping(address => TokenAndAddress[]) public vaultedTokens;
    mapping(address => bool) public allowedContracts;

    event VaultedToken(uint indexed tokenId, address indexed owner, uint unlockTime);
    event UnvaultedToken(uint indexed tokenId, address indexed owner);

    function setAllowedContract(address _contract, bool _allowed) public adminRequired {
        allowedContracts[_contract] = _allowed;
    }

    function setMultiplier(uint[11] memory _multiplier) public adminRequired {
        multiplier = _multiplier;
    }

    // function to remove token ID from addressToTokenIds mapping
    function removeTokenFromVaultedTokens(address _address, uint _tokenId, address _contractAddress) internal {
        TokenAndAddress[] storage tokenIdAndAddresses = vaultedTokens[_address];
        for (uint i = 0; i < tokenIdAndAddresses.length; i++) {
            if (tokenIdAndAddresses[i].tokenId == _tokenId && tokenIdAndAddresses[i].contractAddress == _contractAddress) {
                tokenIdAndAddresses[i] = tokenIdAndAddresses[tokenIdAndAddresses.length - 1];
                tokenIdAndAddresses.pop();
                break;
            }
        }
    }

    /// function to allow users to vault or revault their tokens
    function vault(uint _yearsLocked, uint _tokenId, address _contractAddress) public nonReentrant returns (bool) {
        require(allowedContracts[_contractAddress], "Tokens from this contract are not allowed");
        require(multiplier[_yearsLocked] > 0, "Invalid lock period");

        IERC721 erc721 = IERC721(_contractAddress);
        require(erc721.ownerOf(_tokenId) == msg.sender || erc721.ownerOf(_tokenId) == address(this), "Caller is not the owner of the token");

        address owner = msg.sender;
        uint unlockDT = block.timestamp + uint(_yearsLocked) * 365 days;
        uint priorScore = 0;

        Vaulting storage vaulting = contractTokenIdToVaulting[_contractAddress][_tokenId];

        if (vaulting.owner != address(0)) {
            // If the token is already vaulted, check if it's time to unvault
            require(block.timestamp >= vaulting.unlockDT, "Token is still locked and can't be revaulted yet");

            // If it's unlocked, then
            priorScore = calculatePoints(_tokenId, _contractAddress);
        } else {
            // If the token is not vaulted, transfer the NFT to this contract
            IERC721(_contractAddress).transferFrom(msg.sender, address(this), _tokenId);
        }

        // store the token information in the mapping
        contractTokenIdToVaulting[_contractAddress][_tokenId] = Vaulting(
            block.timestamp,
            owner,
            unlockDT,
            multiplier[_yearsLocked],
            priorScore
        );

        // add the token ID to the addressToTokenIds mapping

        vaultedTokens[owner].push(TokenAndAddress(_contractAddress, _tokenId));

        emit VaultedToken(_tokenId, owner, unlockDT);

        return true;
    }

    function vaultBatch(uint[] memory _yearsLocked, uint[] memory _tokenIds, address[] memory _contractAddresses) public returns (bool) {
        require(_yearsLocked.length == _tokenIds.length && _tokenIds.length == _contractAddresses.length, "Input arrays length mismatch");
        require(_tokenIds.length > 0, "Token IDs array cannot be empty");

        for (uint i = 0; i < _tokenIds.length; i++) {
            vault(_yearsLocked[i], _tokenIds[i], _contractAddresses[i]);
        }
        return true;
    }

    function unvault(uint _tokenId, address _contractAddress) public nonReentrant returns (bool)  {

        Vaulting storage vaulting = contractTokenIdToVaulting[_contractAddress][_tokenId];

        require(vaulting.owner == msg.sender, "Only the owner can unvault the token");
        require(block.timestamp >= vaulting.unlockDT, "Token is still locked");

        // Transfer the token back to the owner
        IERC721(_contractAddress).safeTransferFrom(address(this), msg.sender, _tokenId, "");

        // Remove the token ID from the addressToTokenIds and contractTokenIdToVaulting mappings
        removeTokenFromVaultedTokens(msg.sender, _tokenId, _contractAddress);
        delete contractTokenIdToVaulting[_contractAddress][_tokenId];

        emit UnvaultedToken(_tokenId, msg.sender);

        return true;
    }


    function unvaultBatch(uint[] memory _tokenIds, address[] memory _contractAddresses) public returns (bool) {
        require(_tokenIds.length == _contractAddresses.length, "Input arrays length mismatch");
        require(_tokenIds.length > 0, "Token IDs array cannot be empty");

        for (uint i = 0; i < _tokenIds.length; i++) {
            unvault(_tokenIds[i], _contractAddresses[i]);
        }
        return true;
    }

    function calculatePoints(uint _tokenId, address _contractAddress) public view returns (uint) {
        Vaulting memory vaulting = contractTokenIdToVaulting[_contractAddress][_tokenId];

        // Check if the token has been vaulted, return 0 if not
        if (vaulting.startDT == 0) {
            return 0;
        }

        uint points = 0;
        uint timeElapsed = block.timestamp - vaulting.startDT;

        if (block.timestamp > vaulting.unlockDT) {
            // Calculate points when block.timestamp is greater than unlockDT
            uint lockedTime = vaulting.unlockDT - vaulting.startDT;
            points = (lockedTime * (vaulting.multiplier - multiplier[0])) + timeElapsed * multiplier[0] + vaulting.priorScore;
        } else {
            // Calculate points when block.timestamp is less than or equal to unlockDT
            points = (timeElapsed * vaulting.multiplier) + vaulting.priorScore;
        }

        return points;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}
