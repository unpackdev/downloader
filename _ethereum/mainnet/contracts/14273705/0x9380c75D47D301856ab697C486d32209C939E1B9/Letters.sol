// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* 

	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	@@@@@@@@@@@@@@@@@@@@@8GLLG8@@@@@@@@@@@@@@@@@@@@@
	@@@@@@@@@@@@@@@@@@0f:      :f0@@@@@@@@@@@@@@@@@@
	@@@@@@@@@@@@@@@C1,  ;L8@@0L;  ,1C@@@@@@@@@@@@@@@
	@@@@@@@@@@@0f;  .1G@@0fiif0@@G1.  ;f0@@@@@@@@@@@
	@@@@@@@@0t,  :f8@8Ci,      ,iC@@8f:  ,t0@@@@@@@@
	@@@@@@@L  :L@@0f:              :tG@8L:  L@@@@@@@
	@@@@@@@: ;@@L,        .;;.      .i0@@@; :@@@@@@@
	@@@@@@@: 1@8       :1C8@@8C1:;f0@@@@@@1 :@@@@@@@
	@@@@@@@: 1@8.     C@@@@@@@@@@@@@@@@@@@1 :@@@@@@@
	@@@@@@@: 1@8.    .@@@@@@@@@@@@@@@@@@@@1 :@@@@@@@
	@@@@@@@: 1@8.    .@@@@@@@@@@@@@@@@@@@@1 :@@@@@@@
	@@@@@@@: 1@8.     C@@@@@@@@@@@@@@@@@@@1 :@@@@@@@
	@@@@@@@: 1@8       :1C8@@8C1:;f0@@@@@@1 :@@@@@@@
	@@@@@@@: ;@@L,        .;;.      .10@@@; :@@@@@@@
	@@@@@@@L  :L@@0f:             .:tG@8L:  C@@@@@@@
	@@@@@@@@0t,  :f8@@Ci,      ,iC@@8f:  ,t0@@@@@@@@
	@@@@@@@@@@@0f;  .1G@@0fiif0@@G1.  ;f0@@@@@@@@@@@
	@@@@@@@@@@@@@@@C1,  ;L0@@0L;  ,1C@@@@@@@@@@@@@@@
	@@@@@@@@@@@@@@@@@@0f:      ;f0@@@@@@@@@@@@@@@@@@
	@@@@@@@@@@@@@@@@@@@@@8GLLG8@@@@@@@@@@@@@@@@@@@@@
	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	A characters.group collection

	Contract by mskd.eth (@maskeddd_)

*/

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract Letters is Ownable, ERC721A, ReentrancyGuard {
	string _baseTokenURI;

	uint256 public price = 0.04 ether;
	uint256 public immutable collectionSize = 6666;
	uint256 public immutable maxBatchSize = 10;
	uint256 public immutable reserves = 100;

	uint256 public saleState = 0;

	address public treasuryWallet;

	bytes32 public merkleRoot;
	mapping(address => uint256) public addressToMinted;

	constructor(string memory baseTokenURI_, address _treasuryWallet)
		ERC721A("Letters", "LETTERS")
	{
		_baseTokenURI = baseTokenURI_;
		treasuryWallet = _treasuryWallet;
	}

	modifier callerIsUser() {
		require(tx.origin == msg.sender, "The caller is another contract.");
		_;
	}

	function privateSaleMint(
		uint256 quantity,
		uint256 allowance,
		bytes32[] calldata proof
	) public payable callerIsUser {
		string memory payload = string(abi.encodePacked(_msgSender()));
		require(saleState > 0, "Presale must be active to mint.");
		require(
			_verify(_leaf(Strings.toString(allowance), payload), proof),
			"Invalid Merkle Tree proof supplied."
		);
		require(addressToMinted[_msgSender()] + quantity <= allowance, "Exceeds allowance.");
		require(quantity * price == msg.value, "Invalid funds provided.");

		addressToMinted[_msgSender()] += quantity;
		_safeMint(msg.sender, quantity);
		refundIfOver(price * quantity);
	}

	function publicSaleMint(uint256 quantity) external payable callerIsUser {
		require(saleState > 1, "Sale must be active to mint.");
		require(totalSupply() + quantity <= collectionSize - reserves, "Exceeds max supply.");
		require(quantity <= maxBatchSize, "Cannot mint this many.");
		require(quantity * price == msg.value, "Invalid funds provided.");
		_safeMint(msg.sender, quantity);
		refundIfOver(price * quantity);
	}

	function refundIfOver(uint256 _price) private {
		require(msg.value >= _price, "Need to send more ETH.");
		if (msg.value > _price) {
			payable(msg.sender).transfer(msg.value - _price);
		}
	}

	function devMint(uint256 quantity) external onlyOwner {
		require(totalSupply() + quantity <= reserves, "Exceeds reserved supply.");
		require(quantity % maxBatchSize == 0, "Can only mint a multiple of the maxBatchSize.");
		uint256 numChunks = quantity / maxBatchSize;
		for (uint256 i = 0; i < numChunks; i++) {
			_safeMint(msg.sender, maxBatchSize);
		}
	}

	function setSaleState(uint256 _saleState) public onlyOwner {
		saleState = _saleState;
	}

	function setPrice(uint256 _newPrice) public onlyOwner {
		price = _newPrice;
	}

	function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
		merkleRoot = _merkleRoot;
	}

	function _leaf(string memory allowance, string memory payload) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked(payload, allowance));
	}

	function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
		return MerkleProof.verify(proof, merkleRoot, leaf);
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}

	function setBaseURI(string calldata baseURI) external onlyOwner {
		_baseTokenURI = baseURI;
	}

	function setTreasuryWallet(address wallet) public onlyOwner {
		treasuryWallet = wallet;
	}

	function withdrawMoney() external onlyOwner nonReentrant {
		require(address(this).balance > 0, "No funds to withdraw.");

		_withdraw(treasuryWallet, (address(this).balance * 10) / 100);
		_withdraw(msg.sender, address(this).balance);
	}

	function _withdraw(address _address, uint256 _amount) private {
		(bool success, ) = _address.call{ value: _amount }("");
		require(success, "Transfer failed.");
	}

	function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
		return ownershipOf(tokenId);
	}
}
