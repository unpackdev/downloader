// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Holder.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./SafeMath.sol";

contract Raffle is Ownable, IERC721Receiver, ERC165, ERC721Holder {
    using SafeMath for uint;
	
	event DrawResult(address indexed owner);

	mapping (bytes32 => bool) isRegistered;
	uint32 raffleVersion;

	TokenContract public tokenContract;
    TokenContract public secondContract;

    uint private raffle_end_timestamp;
    uint raffleActivationBlock;
	uint rn;
    uint tokenId;
	uint[] registeredTokens;
    bool requireSecondNFT;

	constructor() public {
	}
	
	function register(uint[] calldata tokenIDs) external {
		require(block.timestamp < raffle_end_timestamp, "registration period expired");
        if(requireSecondNFT) {
            require(secondContract.balanceOf(msg.sender) > 0, "does not own required token in additional contract");
        }

        for (uint i=0; i < tokenIDs.length; i++) {
			require(tokenContract.ownerOf(tokenIDs[i]) == msg.sender , "sender not owner");

            bytes32 key = keccak256(abi.encodePacked(raffleVersion, tokenIDs[i]));

			require(!isRegistered[key], "already used for registration");			

			isRegistered[key] = true;
			registeredTokens.push(tokenIDs[i]);
		}
    }

	function hasRegistered(uint256[] calldata tokenIDs) external view returns (bool[] memory) {
        bool[] memory result = new bool[](tokenIDs.length);
        
        for (uint i=0; i < tokenIDs.length; i++) {
            bytes32 key = keccak256(abi.encodePacked(raffleVersion, tokenIDs[i]));

            if(!isRegistered[key]) {
                result[i] = false;
            } else {
                result[i] = true;
            }
        }
        return result;
    }

    function newRaffle(uint _endTimestamp, uint _tokenId, bool _requireSecondNFT) external onlyOwner {
        raffleVersion++;
        delete registeredTokens;
        raffleActivationBlock = 0;
        rn = 0;
        tokenId = _tokenId;
        raffle_end_timestamp = _endTimestamp;
        requireSecondNFT = _requireSecondNFT;
    }

    function setContracts(address contractAddress, address _secondContract) external onlyOwner {
        tokenContract=TokenContract(contractAddress);
        secondContract=TokenContract(_secondContract);
    }

	function prepareDraw() external {
		require(raffleActivationBlock == 0 && block.timestamp > raffle_end_timestamp, "registration period not expired");
        
		raffleActivationBlock = block.number+2;
	}

	function draw() external {
        require(raffleActivationBlock != 0, "activation block must be set");
        require(block.number > raffleActivationBlock, "block number too low");
		require(rn == 0, "already executed");

        rn = uint(blockhash(raffleActivationBlock));
        if (block.number.sub(raffleActivationBlock) > 255) {
            rn = uint(blockhash(block.number-1));
        }

		address winner = tokenContract.ownerOf(registeredTokens[rn%registeredTokens.length]);

		tokenContract.safeTransferFrom(address(this), winner, tokenId);

        emit DrawResult(winner);

	}

    function getTotalParticipants() external view returns (uint) {
        return registeredTokens.length;
    }

    function getVersion() external view returns (uint) {
        return raffleVersion;
    }    

    function getTokenToWin() external view returns (uint) {
        return tokenId;
    }        

    function getRaffleEnd() external view returns (uint) {
        return raffle_end_timestamp;
    }

    function setRaffleEnd(uint timestamp) external onlyOwner {
        raffle_end_timestamp = timestamp;
    }
}

 interface TokenContract {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
	function ownerOf(uint256 tokenId) external view returns (address);
  	function balanceOf(address owner) external view returns (uint);
 }
