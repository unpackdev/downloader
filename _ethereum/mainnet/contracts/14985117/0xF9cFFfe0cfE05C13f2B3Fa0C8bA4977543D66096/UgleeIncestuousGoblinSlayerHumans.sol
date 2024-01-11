// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721AUpgradeable.sol";

contract UgleeIncestuousGoblinSlayerHumans is
	ERC721AUpgradeable,
	ReentrancyGuardUpgradeable,
	OwnableUpgradeable,
	PausableUpgradeable
{
    event Mint(address _minter, uint256 _startTokenId, uint256 _amount, uint256 _value);

    // Size of the collection
	uint256 public MAX_SUPPLY;

    // Maximum number of tokens to be sold for free
    uint256 public FREE_CAP;

    // Maximum number of tokens reserved for the contract owner
    uint256 public OWNER_CAP;

    // Address of the recipient of accumulated funds
	address payable public TREASURY;

    // Public sale start time
	uint256 public START_TIME;

    // Maximum number of tokens that an address is permitted to mint
	uint256 public TOKEN_LIMIT;

    // Price of a single token
	uint256 public TOKEN_PRICE;

    // Minimum amount of ETH to be sent in order to mint
	uint256 public MIN_VALUE;

	// Base URI for all tokens
    string public BASE_URI;

    // Tracks number of tokens minted by the contract owner
    uint256 public ownerMinted;

    // Tracks number of tokens minted during public sale
    uint256 public publicMinted;

    // Tracks number of tokens minted by a particular address
    mapping(address => uint256) addressMinted;

	modifier onlyEOA() {
		require(msg.sender == tx.origin, "Only wallets allowed");
		_;
	}

    /**
     * @param name_ Name of the contract 
     * @param symbol_ Symbol of the contract 
     * @param treasury_ Address of the recipient of accumulated funds 
     */
	function initialize(
		string memory name_,
		string memory symbol_,
		address payable treasury_
	) public initializer {
		require(treasury_ != address(0), 
            "Initialise: invalid treasury address"
        );
        
		__ERC721A_init(name_, symbol_);
		__Ownable_init();
		__ReentrancyGuard_init();

		MAX_SUPPLY = 10000;
        OWNER_CAP = 100;
        FREE_CAP = 2000;
		TREASURY = treasury_;

		START_TIME = 1655564400;
		TOKEN_LIMIT = 1;
		TOKEN_PRICE = 0.0099 ether;
        MIN_VALUE = 0.0099 ether;
	}

    /**
     * @param _amount Number of tokens to be minted
     */
    function ownerMint(uint256 _amount) external onlyOwner {
        require(
            ownerMinted + _amount <= OWNER_CAP,
            "OwnerMint: exceeding quota"
        );
        require(
            totalSupply() + _amount <= MAX_SUPPLY,
            "OwnerMint: exceeding max supply"
        );
        
        ownerMinted += _amount;
        _mint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply() - _amount + 1, _amount, 0);
    }


    /**
     * @param _amount Number of tokens to be minted
     */
	function mint(uint256 _amount)
		external
		payable
		onlyEOA
		nonReentrant
	{
        uint256 price;

        if (publicMinted < FREE_CAP){
            if (publicMinted + _amount > FREE_CAP){
                price = TOKEN_PRICE * (publicMinted + _amount - FREE_CAP);
            } else {
                price = 0;
            }
        } else {
            price = TOKEN_PRICE * _amount;
        }

		require(
			block.timestamp >= START_TIME,
			"Mint: has not begun"
		);
		require(
			msg.value >=  MIN_VALUE,
			"Mint: insufficient ETH sent"
		);
		require(
			_amount + addressMinted[msg.sender] <=
				TOKEN_LIMIT,
			"Mint: exceeding individual quota"
		);
		require(
			publicMinted + _amount <= MAX_SUPPLY - OWNER_CAP,
			"Mint: exceeding max supply"
		);
		require(
			msg.value >= price,
			"Mint: insufficient ETH paid"
		);

        if (msg.value - price > 0){
            payable(msg.sender).transfer(msg.value - price);
        }
        
		addressMinted[msg.sender] += _amount;
        publicMinted += _amount;
        _mint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply() - _amount + 1, _amount, price);
	}

	
    /**
     * @notice Setters
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
		MAX_SUPPLY = _maxSupply;
	}


    function setFreeMintCap(uint256 _freeCap) external onlyOwner {
        FREE_CAP = _freeCap;
    }


	function setTreasury(address _treasury) external onlyOwner {
		TREASURY = payable(_treasury);
	}

    
    function setOwnerCap(uint256 _ownerCap) external onlyOwner {
        OWNER_CAP = _ownerCap;
    }


    function setStartTime(uint256 _startTime) external onlyOwner {
        START_TIME = _startTime;
    }


    function setMaxMintPerAddress(uint256 _tokenLimit) external onlyOwner {
        TOKEN_LIMIT = _tokenLimit;
    }


    function setPricePerUnit(uint256 _tokenPrice) external onlyOwner {
        TOKEN_PRICE = _tokenPrice;
    }


    function setMinRequiredBalance(uint256 _minValue) external onlyOwner {
        MIN_VALUE = _minValue;
    }


	function setBaseURI(string memory _baseTokenURI) external onlyOwner {
		BASE_URI = _baseTokenURI;
	}


    /**
     * @notice Getters
     */
    function getMintRecord(address _buyer) public view returns (uint256) {
        return addressMinted[_buyer];
    }


    /**
     * @notice Auxiliary
     */
	function withdraw() external onlyOwner {
		require(
            TREASURY != address(0), 
            "Withdraw: treasury address not set"
        );

		TREASURY.transfer(address(this).balance);
	}


	function togglePause() external onlyOwner {
		if (paused()) {
			_unpause();
		} else {
			_pause();
		}
	}


	function _baseURI() internal view virtual override returns (string memory) {
		return BASE_URI;
	}


	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}


	function _beforeTokenTransfers(
		address from,
		address to,
		uint256 startTokenId,
		uint256 quantity
	) internal virtual override whenNotPaused {
		super._beforeTokenTransfers(from, to, startTokenId, quantity);
	}
}
