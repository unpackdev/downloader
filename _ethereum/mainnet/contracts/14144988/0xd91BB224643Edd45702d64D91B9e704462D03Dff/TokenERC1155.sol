// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract TokenERC1155 is ERC1155, Ownable, ERC1155Burnable {
    constructor() ERC1155("") {}

	uint private currTokenId;
	mapping(uint => string) private ipfsHashTable;

	// we could not keep standard mint-function, because we after that we are not able 
	// to get tokenURI of tokens minted by standerd-function from current tokenURI function
	mapping(uint => address) SpecialErc20Tokens;
	mapping(uint => uint) SpErc20MinBalances;
	mapping(uint => uint) NftExpirations;
	mapping(uint => address[]) holdersList;
	mapping(uint => mapping(address => bool)) holdersMap;
	function mint(address account, uint amount, string memory newUri,
		address spErc20Addr, uint spErc20MinBalance,
		uint nftExpiration
	) 
	    public onlyOwner 
	{
		_mint(account, currTokenId, amount, '0x');
		ipfsHashTable[currTokenId] = newUri;

		// Add token properties and condition
		SpecialErc20Tokens[currTokenId] = spErc20Addr;
		SpErc20MinBalances[currTokenId] = spErc20MinBalance;
		NftExpirations[currTokenId] = nftExpiration;
		addToHolders(currTokenId, account);
		
		currTokenId++;
	}

	function uri(uint256 id) public view override returns (string memory) {
	    
        return ipfsHashTable[id];
    }

	function addToHolders(uint tokenId, address tokenHolder) private {
		if(holdersMap[tokenId][tokenHolder] == false) {
			holdersMap[tokenId][tokenHolder] = true;
			holdersList[tokenId].push(tokenHolder);
		}
	}
	function getHoldersList(uint tokenId) public view returns(address[] memory) {
	    return holdersList[tokenId];
	}

	function isTokenExpired(uint tokenId, address user) public view returns (bool) {
	    uint tokenAmount = ERC1155.balanceOf(user, tokenId);
		if(tokenAmount == 0) return false;   // User does not have any token which will expire
		
		// Condition 1: Special ERC20 Token is registered & user has less than required balance
		if(SpecialErc20Tokens[tokenId] != address(0)) {
			if(IERC20(SpecialErc20Tokens[tokenId]).balanceOf(user) < SpErc20MinBalances[tokenId]) return true;
		}
		// Condition 2: NFT Auto Destruct time is passed
		if ( NftExpirations[tokenId] != 0 ) {
			if (block.timestamp > NftExpirations[tokenId]) return true;
		}
		return false;
	}

	function burnExpiredToken(uint tokenId, address user) public {
		uint tokenAmount = ERC1155.balanceOf(user, tokenId);
		if(isTokenExpired(tokenId, user)) _burn(user, tokenId, tokenAmount);
	}

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
		addToHolders(id, to);
    }

	function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
		for(uint i=0; i<ids.length; i++) {
			addToHolders(ids[i], to);
		}
    }

	function getCurrentTokenId() external view returns(uint) {
        return currTokenId;
    }
}

