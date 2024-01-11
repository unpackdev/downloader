// SPDX-License-Identifier: MIT
//
// by collect-code 2022
// https://collect-code.com/
//
pragma solidity ^0.8.2;
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./Ownable.sol";
import "./Address.sol";

interface IChroma is IERC721, IERC721Metadata, IERC721Enumerable {
	// struct State {
	// 	bool isReleased;
	// 	uint256 mintedCount;
	// 	uint256 builtCount;
	// 	uint256 notBuiltCount;
	// 	uint256 currentSupply;
	// 	uint256 availableSupply;
	// 	uint256 maxBuyout;
	// 	bool isAvailable;
	// }
	// function getState() external view returns (State memory);
}

contract ChromaBatch is IERC721, IERC721Metadata, IERC721Enumerable, Ownable {
	
	struct Contract {
		IChroma instance;
		uint8 seriesNumber;
		bool isActive;
	}

	bool public isVisible = true;
	uint256 public constant batchMultiplier = 10000;
	mapping(uint8 => Contract) public contracts;
	uint8[] public series;

	event ContractSetup(address indexed contractAddress, uint8 indexed seriesNumber, bool indexed isActive);
	event ChangedVisibility(bool indexed isVisible);

	constructor(uint8[] memory seriesNumbers, address[] memory contractAddress) {
		for(uint256 i = 0 ; i < seriesNumbers.length && i < contractAddress.length ; i++) {
			setupContract(seriesNumbers[i], contractAddress[i], true);
		}
	}
	
	function setupContract(uint8 seriesNumber, address contractAddress, bool isActive) public onlyOwner {
		require(address(this) != contractAddress, "ChromaBatch: Cannot add self");
		require(Address.isContract(contractAddress), "ChromaBatch: Not a contract");
		validateChromaFunction(contractAddress, "getState()");
		IChroma instance = IChroma(contractAddress);
		if(contracts[seriesNumber].seriesNumber != seriesNumber) {
			series.push(seriesNumber);
		}
		contracts[seriesNumber] = Contract(instance, seriesNumber, isActive);
		emit ContractSetup(contractAddress, seriesNumber, isActive);
	}
	function setVisibility(bool newVisible) onlyOwner public {
		isVisible = newVisible;
		emit ChangedVisibility(isVisible);
	}

	function validateChromaFunction(address contractAddress, string memory functionSignature) internal view {
		bytes4 functionSelector = bytes4(keccak256(bytes(functionSignature)));
		bytes memory data = abi.encodeWithSelector(functionSelector);
		Address.functionStaticCall(contractAddress, data, "ChromaBatch: Contract is not Chroma");
	}

	function getContractForBatchTokenId(uint256 batchTokenId) internal view returns(IChroma instance, uint256 tokenId) {
		require(batchTokenId >= batchMultiplier, "ChromaBatch: Bad Batch Token Id");
		uint8 seriesNumber = uint8(batchTokenId / batchMultiplier);
		Contract memory c = contracts[seriesNumber];
		require(c.seriesNumber == seriesNumber && c.isActive, "ChromaBatch: Batch Token not found");
		return (c.instance, batchTokenId % batchMultiplier);
	}

	// IERC165
	function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
		if(!isVisible) {
			return interfaceId == type(IERC165).interfaceId;
		}
		return
			interfaceId == type(IERC165).interfaceId ||
			interfaceId == type(IERC721).interfaceId ||
			interfaceId == type(IERC721Metadata).interfaceId ||
			interfaceId == type(IERC721Enumerable).interfaceId;
	}

	// IERC721
	// getters
	function balanceOf(address owner) public view override returns (uint256) {
		uint256 result = 0;
		for(uint256 i = 0 ; i < series.length ; i++) {
			Contract memory c = contracts[series[i]];
			if(c.isActive) {
				result += c.instance.balanceOf(owner);
			}
		}
		return result;
	}
	function ownerOf(uint256 batchTokenId) public view override returns (address) {
		(IChroma instance, uint256 tokenId) = getContractForBatchTokenId(batchTokenId);
		return instance.ownerOf(tokenId);
	}
	function getApproved(uint256 /* batchTokenId */) public pure override returns (address) {
		revert("ChromaBatch: Sales disabled");
		// TODO: Enable sales
		// (IChroma instance, uint256 tokenId) = getContractForBatchTokenId(batchTokenId);
		// return instance.getApproved(tokenId);
	}
	function isApprovedForAll(address /* owner */, address /* operator */) public pure override returns (bool) {
		return false;
		// TODO: Enable sales
		// return instance.isApprovedForAll(owner, operator);
	}
	// approvals
	function approve(address /* to */, uint256 /* batchTokenId */) public pure override {
		revert("ChromaBatch: Sales disabled");
		// TODO: Enable sales
		// (IChroma instance, uint256 tokenId) = getContractForBatchTokenId(batchTokenId);
		// instance.approve(to, tokenId);
	}
	function setApprovalForAll(address /* operator */, bool /* approved */) public pure override {
		revert("ChromaBatch: Sales disabled");
		// TODO: Enable sales
		// instance.setApprovalForAll(operator, approved);
	}
	// transfers
	function safeTransferFrom( address /* from */, address /* to */, uint256 /* batchTokenId */) public pure override {
		revert("ChromaBatch: Sales disabled");
		// TODO: Enable sales
		// (IChroma instance, uint256 tokenId) = getContractForBatchTokenId(batchTokenId);
		// require(instance.isApprovedForAll(from, address(this)), "ChromaBatch: Approve Chroma Batch first");
		// instance.safeTransferFrom(from, to, tokenId);
	}
	function safeTransferFrom(address /* from */, address /* to */, uint256 /* batchTokenId */, bytes memory /* _data */) public pure override {
		revert("ChromaBatch: Sales disabled");
		// TODO: Enable sales
		// (IChroma instance, uint256 tokenId) = getContractForBatchTokenId(batchTokenId);
		// require(instance.isApprovedForAll(from, address(this)), "ChromaBatch: Approve Chroma Batch first");
		// instance.safeTransferFrom(from, to, tokenId, _data);
	}
	function transferFrom( address /* from */, address /* to */, uint256 /* batchTokenId */) public pure override {
		revert("ChromaBatch: Sales disabled");
		// TODO: Enable sales
		// (IChroma instance, uint256 tokenId) = getContractForBatchTokenId(batchTokenId);
		// require(instance.isApprovedForAll(from, address(this)), "ChromaBatch: Approve Chroma Batch first");
		// instance.transferFrom(from, to, tokenId);
	}

	// IERC721Enumerable
	function totalSupply() public view override returns (uint256) {
		uint256 result = 0;
		for(uint256 i = 0 ; i < series.length ; i++) {
			Contract memory c = contracts[series[i]];
			if(c.isActive) {
				result += c.instance.totalSupply();
			}
		}
		return result;
	}
	function tokenOfOwnerByIndex(address owner, uint256 batchIndex) public view override returns (uint256) {
		uint256 batchBalance = 0;
		for(uint256 i = 0 ; i < series.length ; i++) {
			Contract memory c = contracts[series[i]];
			if(c.isActive) {
				uint256 index = batchIndex - batchBalance;
				uint256 contractBalance = c.instance.balanceOf(owner);
				if(index < contractBalance) {
					return (series[i] * batchMultiplier) + c.instance.tokenOfOwnerByIndex(owner, index);
				}
				batchBalance += contractBalance;
			}
		}
		revert("ChromaBatch: owner index out of bounds");
	}
	function tokenByIndex(uint256 batchIndex) public view override returns (uint256) {
		uint256 batchSupply = 0;
		for(uint256 i = 0 ; i < series.length ; i++) {
			Contract memory c = contracts[series[i]];
			if(c.isActive) {
				uint256 index = batchIndex - batchSupply;
				uint256 contractSupply = c.instance.totalSupply();
				if(index < contractSupply) {
					return (series[i] * batchMultiplier) + c.instance.tokenByIndex(index);
				}
				batchSupply += contractSupply;
			}
		}
		revert("ChromaBatch: global index out of bounds");
	}

	// IERC721Metadata
	function name() public pure override returns (string memory) {
		return "ChromaBatch";
	}
	function symbol() public pure override returns (string memory) {
		return "CHB";
	}
	function tokenURI(uint256 batchTokenId) public view override returns (string memory) {
		(IChroma instance, uint256 tokenId) = getContractForBatchTokenId(batchTokenId);
		return instance.tokenURI(tokenId);
	}
}
