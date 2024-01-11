// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

// 888       888          888 888       .d8888b.  888         888b     d888
// 888   o   888          888 888      d88P  Y88b 888         8888b   d8888
// 888  d8b  888          888 888      Y88b.      888         88888b.d88888
// 888 d888b 888  8888b.  888 888       "Y888b.   888888      888Y88888P888  .d88b.  88888b.d88b.  .d8888b
// 888d88888b888     "88b 888 888          "Y88b. 888         888 Y888P 888 d88""88b 888 "888 "88b 88K
// 88888P Y88888 .d888888 888 888            "888 888         888  Y8P  888 888  888 888  888  888 "Y8888b.
// 8888P   Y8888 888  888 888 888      Y88b  d88P Y88b.       888   "   888 Y88..88P 888  888  888      X88
// 888P     Y888 "Y888888 888 888       "Y8888P"   "Y888      888       888  "Y88P"  888  888  888  88888P'

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract WallStMoms is ERC721A, Ownable {
	using Strings for uint256;

	enum SaleType {
		WHITELIST_SUPER_FRENS,
		WHITELIST,
		WHITELIST_FREE_MINT,
		PUBLIC_SALE
	}

	event WhiteYeti(address indexed whiteYeti, bool value);

	address public LegenDaddy_ADDRESS = 0x93ed994082734BbEc169e19386f6DC28200A17A3;

	string public baseURI_1;
	string public baseURI_2;
	string public baseURI_3;

	string public notRevealedURI;
	string public PROVENANCE_1;
	string public PROVENANCE_2;
	string public PROVENANCE_3;
	string public baseExtension = ".json";

	bytes32 public merkleRootSF;
	bytes32 public merkleRoot;
	bytes32 public merkleRootFreeMint;

	mapping(address => bool) whiteYetiAddresses;

	mapping(address => bool) mintedSF;
	mapping(address => bool) mintedWhiteYeti;
	mapping(address => uint8) amountMintedWhitelistPhase1;
	mapping(address => uint8) amountMintedWhitelistPhase2;
	mapping(address => uint8) amountMintedWhitelistPhase3;
	mapping(address => bool) freeMintedWithDads;

	uint256 public costWhitelistedSF = 0.00 ether;
	uint256 public costWhitelisted = 0.09 ether;
	uint256 public costPublicSale = 0.12 ether;
	uint256 public costWhiteYeti = 0.09 ether;

	uint16 public phaseMaxSupply1;
	uint16 public phaseMaxSupply2;
	uint16 public phaseMaxSupply3;
	uint16 public currPhaseMaxSupply;

	uint16 public maxMintAmountWhitelistSF = 1;
	uint16 public maxMintAmountWhitelist = 2;
	uint16 public maxMintAmountPublicSale = 2;
	uint16 public maxMintAmountWhiteYeti = 100;
	uint8 public lastRevealedPhase = 0; // possible values: 0, 1, 2, 3. 0 means no phase has been revealed yet.
	uint8 public phase = 1;

	bool public paused = false;
	bool public frozenMetadata = false;
	bool public frozenMaxSupply = false;

	SaleType public currSaleType = SaleType.WHITELIST_SUPER_FRENS;

	constructor(
		string memory _name,
		string memory _symbol,
		string memory _initNotRevealedURI,
		uint16 _phaseMaxSupply1,
		uint16 _phaseMaxSupply2,
		uint16 _phaseMaxSupply3
	) ERC721A(_name, _symbol) {
		setNotRevealedURI(_initNotRevealedURI);
		phaseMaxSupply1 = _phaseMaxSupply1;
		phaseMaxSupply2 = _phaseMaxSupply2;
		phaseMaxSupply3 = _phaseMaxSupply3;
		currPhaseMaxSupply = phaseMaxSupply1;
	}

	//-------MINTING FUNCTIONS-------//
	function mintWhitelistedSF(uint16 _mintAmount, bytes32[] calldata _merkleProof) external payable {
		require(currSaleType == SaleType.WHITELIST_SUPER_FRENS, "Super Frens sale is not active");
		require(isWhitelistedSF(msg.sender, _merkleProof), "You are not whitelisted");
		require(mintedSF[msg.sender] == false, "You already minted");

		require(_mintAmount <= maxMintAmountWhitelistSF, "Max mint amount exceeded");
		require(msg.value >= costWhitelistedSF * _mintAmount, "Insufficient ETH amount");

		mintedSF[msg.sender] = true;
		_mint(_mintAmount);
	}

	function mintWhitelisted_phase1(uint16 _mintAmount, bytes32[] calldata _merkleProof)
		external
		payable
		canWhitelistMint(_mintAmount, _merkleProof)
	{
		require(phase == 1, "Phase 1 is not active");
		require(amountMintedWhitelistPhase1[msg.sender] + _mintAmount <= maxMintAmountWhitelist, "Max mint amount exceeded");

		amountMintedWhitelistPhase1[msg.sender] += uint8(_mintAmount);
		_mint(_mintAmount);
	}

	function mintWhitelisted_phase2(uint16 _mintAmount, bytes32[] calldata _merkleProof)
		external
		payable
		canWhitelistMint(_mintAmount, _merkleProof)
	{
		require(phase == 2, "Phase 2 is not active");
		require(amountMintedWhitelistPhase2[msg.sender] + _mintAmount <= maxMintAmountWhitelist, "Max mint amount exceeded");

		amountMintedWhitelistPhase2[msg.sender] += uint8(_mintAmount);
		_mint(_mintAmount);
	}

	function mintWhitelisted_phase3(uint16 _mintAmount, bytes32[] calldata _merkleProof)
		external
		payable
		canWhitelistMint(_mintAmount, _merkleProof)
	{
		require(phase == 3, "Phase 3 is not active");
		require(amountMintedWhitelistPhase3[msg.sender] + _mintAmount <= maxMintAmountWhitelist, "Max mint amount exceeded");

		amountMintedWhitelistPhase3[msg.sender] += uint8(_mintAmount);
		_mint(_mintAmount);
	}

	modifier canWhitelistMint(uint16 _mintAmount, bytes32[] calldata _merkleProof) {
		require(currSaleType == SaleType.WHITELIST, "Whitelist sale is not active");
		require(isWhitelisted(msg.sender, _merkleProof), "You are not whitelisted");
		require(msg.value >= costWhitelisted * _mintAmount, "Insufficient ETH amount");
		_;
	}

	function mintFreeWithDads(uint16 _mintAmount, bytes32[] calldata _merkleProof) external {
		require(currSaleType == SaleType.WHITELIST_FREE_MINT, "Whitelist Free Mint sale is not active");
		require(isWhitelistedForFreeMint(msg.sender, _mintAmount, _merkleProof), "You are not whitelisted or the amount doesn't match");
		require(freeMintedWithDads[msg.sender] == false, "You already minted your free moms");

		freeMintedWithDads[msg.sender] = true;
		_mint(_mintAmount);
	}

	function mintWithWhiteYeti(uint16 _mintAmount) external payable {
		require(_mintAmount <= maxMintAmountWhiteYeti, "Max mint amount exceeded");
		require(msg.value >= costWhiteYeti * _mintAmount, "Insufficient ETH amount");
		require(whiteYetiAddresses[msg.sender], "You don't have white yeti badge");
		require(mintedWhiteYeti[msg.sender] == false, "You already minted");
		mintedWhiteYeti[msg.sender] = true;
		_mint(_mintAmount);
	}

	function mintPublicSale(uint16 _mintAmount) external payable {
		require(currSaleType == SaleType.PUBLIC_SALE, "Public sale is not active");

		require(_mintAmount <= maxMintAmountPublicSale, "Max mint amount exceeded");
		require(msg.value >= costPublicSale * _mintAmount, "Insufficient ETH amount");

		_mint(_mintAmount);
	}

	function mintOnlyOwner(uint16 _mintAmount) external onlyOwner {
		_mint(_mintAmount);
	}

	//-------VIEW ONLY FUNCTIONS-------//
	function isWhitelistedSF(address _user, bytes32[] calldata _merkleProof) public view returns (bool) {
		bytes32 leaf = keccak256(abi.encodePacked(_user));
		return MerkleProof.verify(_merkleProof, merkleRootSF, leaf);
	}

	function isWhitelisted(address _user, bytes32[] calldata _merkleProof) public view returns (bool) {
		bytes32 leaf = keccak256(abi.encodePacked(_user));
		return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
	}

	function isWhitelistedForFreeMint(
		address _user,
		uint16 _mintAmount,
		bytes32[] calldata _merkleProof
	) public view returns (bool) {
		bytes32 leaf = keccak256(abi.encodePacked(_user, _mintAmount));
		return MerkleProof.verify(_merkleProof, merkleRootFreeMint, leaf);
	}

	function isWhiteYeti(address _user) public view returns (bool) {
		return whiteYetiAddresses[_user];
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "tokenId does not exist");

		if (!isPhaseRevealed(getPhaseForTokenId(tokenId))) {
			return notRevealedURI;
		}

		string memory baseURI = _baseURI(getPhaseForTokenId(tokenId));

		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
	}

	function getPhaseForTokenId(uint256 tokenId) public view returns (uint8) {
		if (tokenId <= phaseMaxSupply1) return 1;
		if (tokenId <= phaseMaxSupply1 + phaseMaxSupply2) return 2;
		return 3;
	}

	function maxSupply() public view returns (uint16) {
		return phaseMaxSupply1 + phaseMaxSupply2 + phaseMaxSupply3;
	}

	//-------VIEWERS FOR SALE PHASE-------//
	function isWhitelistSFSale() public view returns (bool) {
		return currSaleType == SaleType.WHITELIST_SUPER_FRENS;
	}

	function isWhitelistSale() public view returns (bool) {
		return currSaleType == SaleType.WHITELIST;
	}

	function isWhitelistFreeMint() public view returns (bool) {
		return currSaleType == SaleType.WHITELIST_FREE_MINT;
	}

	function isPublicSale() public view returns (bool) {
		return currSaleType == SaleType.PUBLIC_SALE;
	}

	//-------INTERNAL-------//
	function _mint(uint16 _mintAmount) internal {
		require(!paused, "Please wait until unpaused");
		require(_mintAmount > 0, "Need to mint more than 0");
		require(_totalMinted() + _mintAmount <= currPhaseMaxSupply, "Max supply exceeded");
		super._mint(msg.sender, _mintAmount, "", true);
	}

	function isPhaseRevealed(uint8 _phase) internal view returns (bool) {
		return _phase <= lastRevealedPhase;
	}

	function _baseURI(uint8 _phase) internal view returns (string memory) {
		if (_phase == 1) {
			return baseURI_1;
		}
		if (_phase == 2) {
			return baseURI_2;
		}
		return baseURI_3;
	}

	function _startTokenId() internal pure override returns (uint256) {
		return 1;
	}

	//-------ONLY OWNER-------//

	//SETTERS FOR STRINGS
	function setBaseURI(string memory _newBaseURI, uint8 _phase) public onlyOwner validPhase(_phase) {
		require(!frozenMetadata, "Metadata is frozen");

		if (_phase == 1) {
			baseURI_1 = _newBaseURI;
		} else if (_phase == 2) {
			baseURI_2 = _newBaseURI;
		} else if (_phase == 3) {
			baseURI_3 = _newBaseURI;
		}
	}

	function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
		notRevealedURI = _notRevealedURI;
	}

	function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
		baseExtension = _newBaseExtension;
	}

	//SETTERS FOR PROVENANCE
	function setProvenanceHash_1(string memory _provenanceHash) public onlyOwner {
		PROVENANCE_1 = _provenanceHash;
	}

	function setProvenanceHash_2(string memory _provenanceHash) public onlyOwner {
		PROVENANCE_2 = _provenanceHash;
	}

	function setProvenanceHash_3(string memory _provenanceHash) public onlyOwner {
		PROVENANCE_3 = _provenanceHash;
	}

	//SETTERS FOR PAUSED, REVEALED, FREEZE METADATA AND PHASE
	function setPaused(bool _state) public onlyOwner {
		paused = _state;
	}

	function unreveal() public onlyOwner {
		lastRevealedPhase = 0;
	}

	function revealPhase1(string memory _baseURI_1) public onlyOwner {
		require(lastRevealedPhase == 0, "Cannot reveal this phase");
		lastRevealedPhase = 1;
		if (!frozenMetadata) {
			baseURI_1 = _baseURI_1;
		}
	}

	function revealPhase2(string memory _baseURI_2) public onlyOwner {
		require(lastRevealedPhase == 1, "Cannot reveal this phase");
		lastRevealedPhase = 2;
		if (!frozenMetadata) {
			baseURI_2 = _baseURI_2;
		}
	}

	function revealPhase3(string memory _baseURI_3) public onlyOwner {
		require(lastRevealedPhase == 2, "Cannot reveal this phase");
		lastRevealedPhase = 3;
		if (!frozenMetadata) {
			baseURI_3 = _baseURI_3;
		}
	}

	function freezeMetadata() public onlyOwner {
		require(bytes(baseURI_1).length > 0, "BaseURI 1 is not set");
		require(bytes(baseURI_2).length > 0, "BaseURI 2 is not set");
		require(bytes(baseURI_3).length > 0, "BaseURI 3 is not set");
		require(phase == 3, "Phase is not 3");

		frozenMetadata = true;
	}

	function freezeMaxSupply() public onlyOwner {
		require(phase == 3, "Phase is not 3");
		frozenMaxSupply = true;
	}

	function setPhase(uint8 _phase) public onlyOwner validPhase(_phase) {
		require(_phase >= 1 && _phase <= 3, "Phase must be between 1 and 3");
		phase = _phase;
		currPhaseMaxSupply = calculatePhaseMaxSupply(phase);
	}

	function calculatePhaseMaxSupply(uint8 _phase) public view onlyOwner returns (uint16) {
		if (_phase == 1) {
			return phaseMaxSupply1;
		}
		if (_phase == 2) {
			return phaseMaxSupply1 + phaseMaxSupply2;
		}
		if (_phase == 3) {
			return phaseMaxSupply1 + phaseMaxSupply2 + phaseMaxSupply3;
		}
		return 0;
	}

	modifier validPhase(uint8 _phase) {
		require(_phase <= 3, "Phase must be 1, 2 or 3");
		_;
	}

	//SETTERS FOR SALE PHASE
	function setWhitelistSFSale() public onlyOwner {
		currSaleType = SaleType.WHITELIST_SUPER_FRENS;
	}

	function setWhitelistSale() public onlyOwner {
		currSaleType = SaleType.WHITELIST;
	}

	function setWhitelistFreeMintSale() public onlyOwner {
		currSaleType = SaleType.WHITELIST_FREE_MINT;
	}

	function setPublicSale() public onlyOwner {
		currSaleType = SaleType.PUBLIC_SALE;
	}

	//SETTERS FOR COSTS
	function setCostWhitelistedSF(uint256 _newCostWhitelisted) public onlyOwner {
		costWhitelistedSF = _newCostWhitelisted;
	}

	function setCostWhitelisted(uint256 _newCostWhitelisted) public onlyOwner {
		costWhitelisted = _newCostWhitelisted;
	}

	function setCostPublicSale(uint256 _newCostPublicSale) public onlyOwner {
		costPublicSale = _newCostPublicSale;
	}

	function setCostWhiteYeti(uint256 _newCostWhiteYeti) public onlyOwner {
		costWhiteYeti = _newCostWhiteYeti;
	}

	//SETTERS FOR MAXMINTAMOUNT
	function setMaxMintAmountWhitelistSF(uint16 _maxMintAmount) public onlyOwner {
		maxMintAmountWhitelistSF = _maxMintAmount;
	}

	function setMaxMintAmountWhitelist(uint16 _maxMintAmount) public onlyOwner {
		maxMintAmountWhitelist = _maxMintAmount;
	}

	function setMaxMintAmountPublicSale(uint16 _maxMintAmount) public onlyOwner {
		maxMintAmountPublicSale = _maxMintAmount;
	}

	function setMaxMintAmountWhiteYeti(uint16 _maxMintAmount) public onlyOwner {
		maxMintAmountWhiteYeti = _maxMintAmount;
	}

	//SETTER FOR PHASE MAXSUPPLY
	function setPhaseMaxSupply(uint8 _phase, uint16 _newPhaseMaxSupply) public onlyOwner {
		require(!frozenMaxSupply, "Max supply is frozen");
		require(_phase == 1 || _phase == 2 || phase == 3, "Phase must be 1, 2 or 3");
		if (_phase == 1) {
			phaseMaxSupply1 = _newPhaseMaxSupply;
		} else if (_phase == 2) {
			phaseMaxSupply2 = _newPhaseMaxSupply;
		} else if (_phase == 3) {
			phaseMaxSupply3 = _newPhaseMaxSupply;
		}
		if (phase == _phase) {
			currPhaseMaxSupply = calculatePhaseMaxSupply(phase);
		}
	}

	//SETTERS FOR WHITELISTS
	function setWhitelist(bytes32 _merkleRoot) external onlyOwner {
		merkleRoot = _merkleRoot;
	}

	function setWhitelistSF(bytes32 _merkleRoot) external onlyOwner {
		merkleRootSF = _merkleRoot;
	}

	function setWhitelistForFreeMint(bytes32 _merkleRoot) external onlyOwner {
		merkleRootFreeMint = _merkleRoot;
	}

	function setWhiteYetiAddress(address _yetiAddress, bool value) external onlyOwner {
		whiteYetiAddresses[_yetiAddress] = value;
		emit WhiteYeti(_yetiAddress, value);
	}

	//WITHDRAWALS
	function withdraw() public payable onlyOwner {
		// ================This will pay 2%=========================
		(bool coldsuccess, ) = payable(LegenDaddy_ADDRESS).call{value: (address(this).balance * 2) / 100}("");
		require(coldsuccess);
		// ====================================================================

		// This will payout the OWNER the remainder of the contract balance if any left.
		(bool os, ) = payable(owner()).call{value: address(this).balance}("");
		require(os);
		// =====================================================================
	}
}
