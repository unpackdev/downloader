//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRenderer.sol";
import "./BaseOpenSea.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

/**
* @title ROC (RebelsOnChain)
* @dev ROC is an initial release of project SPACESHIP128, this contract
* implements ERC-721 tokenomics of the release. NFTs within this release
* are categorized by generations and types. Contract assumes that owner
* will set the minting phases and renderer contract addresses manually.
* Generations and Types Below.
* (tokenIds > 0 && <= 512) = Male Rebels-Gen0
* (tokenIds > 512 && <= 1024) = Female Rebels-Gen0
* (tokenIds > 1024) = Rebels-Gen1.
* @author Tfs128.eth (@trickerfs128)
*/
contract Roc is BaseOpenSea, Ownable, ERC721Enumerable, ERC721Burnable {

	event RendererSet(uint8 indexed rtype, address indexed rAddress);
	event Collected(address indexed operator, uint256 indexed count,uint256 value);
	event Bred(address indexed operator, uint256 indexed tokenId);
	event BreedPriceSet(uint256 indexed tokenId, uint256 value);
	event Withdrawn(address indexed operator, uint256 value);

	uint8 private constant MAX_CHILDS_PER_GEN0 = 15;
	uint16 private constant PHASE1_LAST = 512;
	uint16 private constant PHASE2_LAST = 1024;
	uint256 private constant MIN_BREED_PRICE = 50000000000000000; // 0.05 eth
	uint256 private constant MAX_BREED_PRICE = 5000000000000000000; // 5 eth

	uint256 private lastTokenId;
	uint256 private lastDna;
	bytes32 private merkleRoot;

	bool public locked;
	uint8 public phase;
	uint8 public sp128Share;
	uint256 public wlSaleTimestamp;
	uint256 public wlPrice;
	uint256 public price;
	address public renderer1;
	address public renderer2;
	address public renderer3;

	struct Parents {
		uint256 father;
		uint256 mother;
	}

	mapping(uint256 => Parents) public _parents;
	mapping(uint256 => uint256) public _dna;
	mapping(uint256 => uint256) public _breed_prices;
	mapping(uint256 => uint256) public _child_rem;
	mapping(address => uint256) public _balances;
	mapping(address => bool) private _p1_wl_claimed;
	mapping(address => bool) private _p2_wl_claimed;
	mapping(address => bool) private _p3_wl_claimed;

	/** 
	 * @notice constructor
     * @param contractURI can be empty
     * @param openseaProxyRegistry can be address zero
     */
    constructor(
        string memory contractURI,
        address openseaProxyRegistry
    ) ERC721('RebelsOnChain', 'ROC') {
        if (bytes(contractURI).length > 0) {
            _setContractURI(contractURI);
        }

        if (address(0) != openseaProxyRegistry) {
            _setOpenSeaRegistry(openseaProxyRegistry);
        }
    }

    /**
     * @notice func to mint gen0 tokens (Phase 1 and 2).
     * @param count - numbers of token to mint. Max 2 allowed per trans.
     */
    function regularMint(uint256 count) external payable {
    	require (phase == 1 || phase == 2, '!allowed.');
    	require (block.timestamp >= wlSaleTimestamp, 'wait');
    	require (count > 0 && count < 3, '1 or 2.');
    	uint16 maxSupplyInPhase = phase == 1 ? PHASE1_LAST : PHASE2_LAST;
    	require (lastTokenId + count <= maxSupplyInPhase, '!available');
    	require(msg.value == price * count, '!enough amount.');
    	_mintRebel(count);
    }

    /**
     * @notice func to mint gen1 tokens (phase 3) by breeding 1 male gen-0
     * and 1 female gen-0.
     * @param motherId - tokenid of female-gen0.
     * @param fatherId - tokenid of male - gen0.
     */
    function breed(uint256 motherId, uint256 fatherId) external payable {
    	require (phase == 3, '!breeding phase.');
    	require (block.timestamp >= wlSaleTimestamp, 'wait');
    	_breed(motherId, fatherId);
    }

    /**
     * @notice func to mint gen-0 tokens within whitelisting period.
     * @param proof - merkle tree proof contraining sibling hashes.
     */
    function wlMint(bytes32[] memory proof) external payable {
		require (block.timestamp < wlSaleTimestamp, 'late.');
		require(msg.value == wlPrice, '!enough amount.');
		if(phase == 1) {
			require(lastTokenId < PHASE1_LAST, '!available');
			require(_p1_wl_claimed[msg.sender] == false, 'already claimed.');
			require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "!whiteListed.");
			_p1_wl_claimed[msg.sender] = true;
			_mintRebel(1);

		}
		else if(phase == 2) {
			require(lastTokenId < PHASE2_LAST, '!available');
			require(_p2_wl_claimed[msg.sender] == false, 'already claimed.');
			require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "!whiteListed.");
			_p2_wl_claimed[msg.sender] = true;
			_mintRebel(1);
		}
		else {
			revert();
		}
	}

	/**
     * @notice func to mint gen-1 tokens within whitelisting period.
     * @param proof - merkle tree proof contraining sibling hashes.
     * @param motherId - tokenid of female-gen0.
     * @param fatherId - tokenid of male - gen0.
     */
	function wlBreed(bytes32[] memory proof, uint256 motherId, uint256 fatherId) external payable {
    	require (phase == 3, '!breeding phase.');
		require (block.timestamp < wlSaleTimestamp, 'late.');
		require(_p3_wl_claimed[msg.sender] == false, 'already claimed.');
		require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "!whiteListed.");
		_p3_wl_claimed[msg.sender] = true;
		_breed(motherId,fatherId);
    }

    /**
     * @notice func to set breeding price of gen-0 tokens by token owners.
     * @param tokenId - gen-0 tokenId.
     * @param price_ - breeding price (wei).
     */
    function setBreedingPrice(uint256 tokenId, uint256 price_) external {
		require(ownerOf(tokenId) == msg.sender, 'Not a token owner.');
		require(_child_rem[tokenId] > 0, '!allowed.');
		require(price_ >= MIN_BREED_PRICE && price_ <= MAX_BREED_PRICE, 'Price must be in between 0.05 and 5 eth.');
		_breed_prices[tokenId] = price_;
		emit BreedPriceSet(tokenId,price_);
	}

	/** 
	 * @notice func to withdraw balance.
	 * @dev contract owner will also have to withdraw balance using 
	 * this func. this withdrawal function will restric contract
	 * owner to empty all the funds.
	 */
	function withdraw() external {
    	require(_balances[msg.sender] > 0, '0 Balance.');
    	uint256 amount = _balances[msg.sender];
    	_balances[msg.sender] = 0;
        bool success;
        (success, ) = msg.sender.call{value: amount}('');
        require(success, 'Failed');
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice func to set configuration (onlyOwner)
     * @param phase_ - 1 || 2 || 3
     * @param ownerShare - must be <= 30%
     * @param hours_ - hours to add in config set time.
     * @param wlPrice_ - token price within whitelisting period.
     * @param price_ - token price at the time of public sale.
     */
    function configure(
    	uint8 phase_,
    	uint8 ownerShare,
        uint256 hours_,
    	uint256 wlPrice_,
    	uint256 price_
    	)
    external onlyOwner
    {
       require (locked == false, '!Allowed.');
       require (ownerShare < 31, 'Must be <= 30.');
       if(phase_ == 1) {
       	require(lastTokenId < PHASE1_LAST, '!');
       }
       else if(phase_ == 2) {
       	require(lastTokenId >= PHASE1_LAST && lastTokenId < PHASE2_LAST, '!!');
       }
       else {
       	require(lastTokenId >= PHASE2_LAST, '!!!');
       }
       phase = phase_;
       wlPrice = wlPrice_;
       price = price_;
       sp128Share = ownerShare;
       wlSaleTimestamp = block.timestamp + (hours_ * 1 hours);
    }

    /**
     * @notice func to update merkle root. (only owner).
     * @dev tokens within this contract will be allowed for 
     * minting within 3 phases. So this contract assumes that
     * owner will update the merkle root manullay according to 
     * phase.
     * @param root - merkle root.
     */
    function updateMerkleRoot(bytes32 root) external onlyOwner {
    	require (locked == false, '!Allowed.');
    	merkleRoot = root;
    }

    /** 
     * @notice func to lock contract for config modifications.
     */
    function lockForModifications(uint256 confirm) external onlyOwner {
    	require(confirm == 11410198101108115, 'needs confirmation.');
    	locked = true;
    }

    /**
     * @notice func to set renderer contract addresses.
     */
    function setRenderer(address renderer, uint8 rendererNo) external onlyOwner {
    	require (locked == false, '!Allowed.');
        if(rendererNo == 1) {
        	renderer1 = renderer;
        }
        else if(rendererNo == 2) {
        	renderer2 = renderer;
        }
        else {
        	renderer3 = renderer;
        }
        emit RendererSet(rendererNo, renderer);
    }

    /**
     * @notice func to mint ownerAllocated tokens.
     * @dev 8 tokens from phase 1 and 2 are allocated
     * for owner. owner will have to mint their token
     * before activating sale.
     */
    function ownerMint() external onlyOwner {
    	require(lastTokenId == 0 || lastTokenId == PHASE1_LAST, '!allowed');
    	_mintRebel(8);
    }

    /**
     * opensea config (https://docs.opensea.io/docs/contract-level-metadata)
     */
    function setContractURI(string memory contractURI) external onlyOwner {
        _setContractURI(contractURI);
    }

    /** 
     * @notice tokenURI override that returns a data:json application
     * @inheritdoc ERC721
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'URI query for nonexistent token');
        if(tokenId > 0 && tokenId <= PHASE1_LAST) {
        	return IRenderer(renderer1).render(tokenId, _dna[tokenId]);
        }
        else if(tokenId > PHASE1_LAST && tokenId <= PHASE2_LAST) {
        	return IRenderer(renderer2).render(tokenId, _dna[tokenId]);
        }
        else {
        	return IRenderer(renderer3).render(tokenId, _dna[tokenId]);
        }
    }

    /**
     * @notice internal func for minting token by breeding
     * two gen-0 and handling complete breeding, balances,
     * and token data.
     */
	function _breed(uint256 motherId,uint256 fatherId) internal {
		require(_exists(motherId), 'motherId: non-existing token.');
		require(_exists(fatherId), 'motherId: non-existing token.');
		require(fatherId > 0 && fatherId <= PHASE1_LAST, 'Need 1 Male and 1 Female Gen-0 Rebel.');
		require(motherId > PHASE1_LAST && motherId <= PHASE2_LAST, 'Need 1 Male and 1 Female Gen-0 Rebel.');
		require(_child_rem[motherId] > 0 && _child_rem[fatherId] > 0, 'Max child limit reached.');
		require(msg.value == (_breed_prices[motherId] + _breed_prices[fatherId]), 'Not Enough Amount.');
		_child_rem[motherId]--;
		_child_rem[fatherId]--;
		uint256 spShareFromMother = (_breed_prices[motherId] * sp128Share * 100) / 10000;
		uint256 spShareFromFather = (_breed_prices[fatherId] * sp128Share * 100) / 10000;
		_balances[owner()] += (spShareFromMother + spShareFromMother);
		_balances[ownerOf(motherId)] += (_breed_prices[motherId] - spShareFromMother);
		_balances[ownerOf(fatherId)] += (_breed_prices[fatherId] - spShareFromFather);
		uint256 tokenId = lastTokenId;
		bytes32 blockHash = blockhash(block.number - 1);
		tokenId++;
		// generating dna by drawing pr num by hashing special
		// variables. Drawing with this implementation can be
		// manipulated but it is fair enough for the given purpose.
		uint256 nextDNA = uint256(keccak256(abi.encodePacked(
			lastDna,
			block.timestamp,
			msg.sender,
			blockHash,
			block.coinbase,
			block.difficulty,
			tx.gasprice
			)));
		_dna[tokenId] = nextDNA;
		lastDna = nextDNA;
		lastTokenId = tokenId;
		_parents[tokenId].father = fatherId;
		_parents[tokenId].mother = motherId;
		_safeMint(msg.sender, tokenId);
		emit Bred(msg.sender, tokenId);
	}

	/**
     * @notice internal func to mint token and setting
     * token data.
     */
	function _mintRebel(uint256 count) internal {
		uint256 tokenId = lastTokenId;
		bytes32 blockHash = blockhash(block.number - 1);
		uint256 nextDNA;
		_balances[owner()] += msg.value;
		for (uint256 i; i < count; i++) {
            tokenId++;
            // generating dna by drawing pr num by hashing special
            // variables. Drawing with this implementation can be
            // manipulated but it is fair enough for the given purpose.
            nextDNA = uint256(keccak256(abi.encodePacked(
            	lastDna,
            	block.timestamp,
            	msg.sender,
            	blockHash,
            	block.coinbase,
            	block.difficulty,
            	tx.gasprice
            	)));
            _dna[tokenId] = nextDNA;
            _breed_prices[tokenId] = MIN_BREED_PRICE;
            _child_rem[tokenId] = MAX_CHILDS_PER_GEN0;
            lastDna = nextDNA;
            lastTokenId = tokenId;
            _safeMint(msg.sender, tokenId);
        }
        emit Collected(msg.sender, count, msg.value);
	}

	/////////////////////// Internal ////////////////////////

	/**
	 * @inheritdoc	ERC721
	 */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    	internal
    	override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @inheritdoc	ERC165
     */
	function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev approve proxy for token transfers.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (isOwnersOpenSeaProxy(owner, operator)) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
	


}
