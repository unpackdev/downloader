//SPDX-License-Identifier: BSD 
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

/////////////////////////////////////

contract PizzaPuffers is ERC721A, Ownable, ReentrancyGuard {
    uint16 public constant MAX_TOTAL_TOKENS = 5555;

    uint16 public constant MAX_OG_TOKENS = 1000;
    uint16 public constant MAX_WL_TOKENS = 2000;

    uint16 public constant MAX_OG_FREE_TOKENS = 400;
    uint16 public constant MAX_WL_FREE_TOKENS = 100;
    uint16 public constant MAX_TOTAL_FREE_TOKENS = MAX_OG_FREE_TOKENS + MAX_WL_FREE_TOKENS;

    // same slot
    uint16 public constant OG_MINT_DURATION = 60*30; // 30 minutes 
    uint16 public constant WL_MINT_DURATION = 60*60; // 60 minutes 

    uint256 public constant MAX_OG_MINTS_PER_WALLET = 2;
    uint256 public constant MAX_WL_MINTS_PER_WALLET = 2;

    // prices
    uint256 public constant MINT_PRICE_OG = 0.055 ether;
    uint256 public constant MINT_PRICE_WL = 0.066 ether;
    uint256 public constant MINT_PRICE_PUBLIC = 0.077 ether;
    // end constants

    // writer: contract
    // reader: contract
    mapping (address => bool) private __has_minted_free;
    uint16 private __og_free_claimed;
    uint16 private __wl_free_claimed;

    uint16 private __total_og_claimed;
    mapping (address => uint8) private __n_og_minted;

    uint16 private __total_wl_claimed;
    mapping (address => uint8) private __n_wl_minted;

    // writer: owner
    // reader: contract 
    uint256 private _mint_start;
    bytes32 private _merkle_root_og;
    bytes32 private _merkle_root_wl;
    bool private _halt_mint = true;
    bool private _is_revealed;
    string private _URI;

    constructor() public ERC721A("PizzaPuffers", "ZAPUFS") payable {}

    function mint_og(uint256 quantity, bytes32[] memory proof) internal {
        // are on the OG list
        require(MerkleProof.verify(proof, _merkle_root_og, keccak256(abi.encodePacked(msg.sender))), "u!WL"); 

        // not minting too much
        require(quantity <= MAX_OG_MINTS_PER_WALLET, ">quantity");

        // need to have enough ETH to mint
        require(quantity*MINT_PRICE_OG == msg.value, "$ETH<");

        // per user check
        require((__n_og_minted[msg.sender] + quantity) <= MAX_OG_MINTS_PER_WALLET, "overminting"); 

        // global mint check
        require((__total_og_claimed + quantity) <= MAX_OG_TOKENS, "overminting:supply");

        // free eligibility
        if ((__has_minted_free[msg.sender] == false) && ((__og_free_claimed + 1) <= MAX_OG_FREE_TOKENS)) {
            require((__og_free_claimed + 1) <= MAX_OG_FREE_TOKENS, "over free total.");

            unchecked{
                __og_free_claimed++;
            }
            __has_minted_free[msg.sender] = true;

            // refund one tokens value
            (bool sent, ) = payable(msg.sender).call{value: MINT_PRICE_OG}("");
            require(sent, "!refund");
        }

        // increment
        unchecked {
            // per user bought
            __n_og_minted[msg.sender] += uint8(quantity);

            // global minted
            __total_og_claimed += uint16(quantity);
        }

        _safeMint(msg.sender, quantity);
    } 

    function mint_wl(uint256 quantity, bytes32[] memory proof) internal {
        // are on the wl
        require(MerkleProof.verify(proof, _merkle_root_wl, keccak256(abi.encodePacked(msg.sender))), "u!WL"); 

        // not minting too much
        require(quantity <= MAX_WL_MINTS_PER_WALLET, ">quantity");

        // need to have enough ETH to mint
        require(quantity*MINT_PRICE_WL == msg.value, "$ETH<");

        // per user check
        require((__n_wl_minted[msg.sender] + quantity) <= MAX_WL_MINTS_PER_WALLET, "overminting"); 

        // global mint check
        require((__total_wl_claimed + quantity) <= MAX_WL_TOKENS, "overminting:supply");

        // free eligibility
        if ((__has_minted_free[msg.sender] == false) && ((__og_free_claimed + __wl_free_claimed + 1) <= MAX_TOTAL_FREE_TOKENS)) {
            require((__og_free_claimed + __wl_free_claimed + 1) <= MAX_TOTAL_FREE_TOKENS, "over free total.");

            unchecked{
                __wl_free_claimed++;
            }
            __has_minted_free[msg.sender] = true;

            // refund one tokens value
            (bool sent, ) = payable(msg.sender).call{value: MINT_PRICE_WL}("");
            require(sent, "!refund");
        }

        // increment
        unchecked {
            // per user bought
            __n_wl_minted[msg.sender] = __n_wl_minted[msg.sender] + uint8(quantity);

            // global minted
            __total_wl_claimed = __total_wl_claimed + uint16(quantity);
        }

        _safeMint(msg.sender, quantity);
    } 

    function mint_public(uint256 quantity) internal {
        // its the public mint
        require(quantity * MINT_PRICE_PUBLIC == msg.value, "$ETH<"); 

        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity, bytes32[] memory proof) external payable nonReentrant {
        require(_halt_mint == false, "Halted");

        require(quantity > 0, "q<0");
        require(quantity < 10, "q>9");

        require((totalSupply() + quantity) <= MAX_TOTAL_TOKENS, ">maxTokens");

        require(_mint_start != 0, "!r:E0");
        require(block.timestamp >= _mint_start, "!r:E1");

        // og mint
        // [T, T+Xmin) 
        if ((block.timestamp >= _mint_start) && (block.timestamp < (_mint_start + OG_MINT_DURATION))) {
            require(proof.length > 0, "!p");
            mint_og(quantity, proof);    
            return;
        }

        // wl mint
        // [T+Xmin, T+Xmin+Ymin) 
        if ((block.timestamp >= (_mint_start + OG_MINT_DURATION)) && (block.timestamp < (_mint_start + OG_MINT_DURATION + WL_MINT_DURATION))) {
            require(proof.length > 0, "!p");
            mint_wl(quantity, proof);
            return;
        }

        // public mint
        // [T+Xmin+Ymin, \inf+)
        mint_public(quantity);
    }

    function getMintInfo() public view virtual returns (uint8, uint256, uint256) {
        if ((block.timestamp >= _mint_start) && (block.timestamp < (_mint_start + OG_MINT_DURATION))) {
            return (1, MINT_PRICE_OG, totalSupply());
        }

        if ((block.timestamp >= (_mint_start + OG_MINT_DURATION)) && (block.timestamp < (_mint_start + OG_MINT_DURATION + WL_MINT_DURATION))) {
            return (2, MINT_PRICE_WL, totalSupply());
        }

        if (block.timestamp >= (_mint_start + OG_MINT_DURATION + WL_MINT_DURATION)) {
            return (3, MINT_PRICE_PUBLIC, totalSupply());
        }

        return (0, MINT_PRICE_PUBLIC, 0);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // Include the token index if revealed
        if (_is_revealed) {
            require(_exists(tokenId), 'tokenId?');
            return string(abi.encodePacked(_URI, toString(tokenId)));
        } 

        // Otherwise return the URI
        return string(_URI);
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    **/
    function withdraw() public onlyOwner() {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    //////////////////////////////////////////////////////////////////////////
    // Begin setter onlyOwner functions
    /**
     * @dev Set _mint_start
    **/
    function setMintStart(uint256 v) public onlyOwner() {
        _mint_start = v;
    }

    /**
     * @dev Set halt minting 
    */
    function setHaltMint(bool v) public onlyOwner() {
        _halt_mint = v;
    }

    /**
     * @dev Set merkle og root 
    */
    function setMerkleRootOG(bytes32 v) public onlyOwner() {
        _merkle_root_og = v;
    }

    /**
     * @dev Set merkle root wl 
    */
    function setMerkleRootWL(bytes32 v) public onlyOwner() {
        _merkle_root_wl = v;
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
    // End setter onlyOwner functions
    //////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////
	// Begin util functions
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
    // end util functions
    //////////////////////////////////////////////////////////////////////////
}
