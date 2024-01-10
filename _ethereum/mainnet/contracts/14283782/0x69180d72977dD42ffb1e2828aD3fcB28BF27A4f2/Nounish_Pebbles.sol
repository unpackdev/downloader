//SPDX-License-Identifier: BSD 
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


abstract contract PointlessPebbles {
        function balanceOf(address owner) view public virtual returns (uint);
        function tokenOfOwnerByIndex(address owner, uint256 index) view public virtual returns (uint256);
        function ownerOf(uint256 idx) view public virtual returns (address);
}

contract NounishPebbles is ERC721A, Ownable, ReentrancyGuard {
    uint16 public constant MAX_TOTAL_TOKENS = 727;

    address public POINTLESS_PEBBLES;
    bool private _halt_mint = true;
    bool private _is_revealed;
    string private _URI;

    // this is a packed array of booleans
    mapping(uint256 => uint256) private _token_used;


    constructor(address pointlesPebblesContract_) ERC721A("NounishPebbles", "NOUNPBLS") {
        POINTLESS_PEBBLES = pointlesPebblesContract_;
    }

    function mint(uint256[] memory openSeaTokenNumbers) external nonReentrant {
        require(_halt_mint == false, "Halted");
        require(openSeaTokenNumbers.length > 0, "quantity>0");

        PointlessPebbles pointlessPebbles = PointlessPebbles(POINTLESS_PEBBLES);

        uint256 elegibleForRedemption;
        
        for (uint i = 0; i < openSeaTokenNumbers.length; i++) {
            require(openSeaTokenNumbers[i] != 0, "no token number 0");
            // tokenID is 0 indexed while the opensea number is 1 indexed, subtract by one
            uint256 tokenId = openSeaTokenNumbers[i] - 1;
            if (!isClaimed(tokenId)) {
                require(pointlessPebbles.ownerOf(tokenId) == msg.sender, "trying to redeem unowned token!");
                _setClaimed(tokenId);
                elegibleForRedemption += 1;
            }

        }

        _safeMint(msg.sender, elegibleForRedemption);
    }

    function isOpenSeaTokenNumberClaimed(uint256 openSeaTokenNumber_) public view returns (bool) {
        return isClaimed(openSeaTokenNumber_ - 1);
    }

    function isClaimed(uint256 tokenId_) public view returns (bool) {
        uint256 claimedWordIndex = tokenId_ / 256;
        uint256 claimedBitIndex = tokenId_ % 256;
        uint256 claimedWord = _token_used[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 tokenId_) private {
        uint256 claimedWordIndex = tokenId_ / 256;
        uint256 claimedBitIndex = tokenId_ % 256;
        _token_used[claimedWordIndex] = _token_used[claimedWordIndex] | (1 << claimedBitIndex);
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'tokenId?');

        // include the token index if revealed
        if (_is_revealed) {
            return string(abi.encodePacked(_URI, toString(tokenId)));
        } 

        // otherwise return the URI
        return string(_URI);
    }

    /**
     * @dev Halt minting 
    */
    function setHaltMint(bool v) public onlyOwner() {
        _halt_mint = v;
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    **/
    function withdraw() public onlyOwner() {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Set URI 
    */
    function setURI(string memory v) public onlyOwner() {
        _URI = v;
    }

    /**
     * @dev Set reveal 
    */
    function setIsReveal(bool v) public onlyOwner() {
        _is_revealed = v;
    }

	/////////////////////////////////////////////
	function toString(uint256 value) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}
}