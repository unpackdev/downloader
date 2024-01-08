//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC721Metadata.sol";
import "./IERC1155MetadataURI.sol";
import "./Address.sol";
import "./Strings.sol";

contract BCRAvatar is Ownable, ERC20 {
	struct AvatarNFT {
		address nft;
		uint256 tokenId;
		bool isERC721;
	}

	event AvatarCreated(address indexed account, string avatarURI);
	event AvatarUpdated(address indexed account, string avatarURI);
	event ProfileCreated(address indexed account, string profileURI);
	event ProfileUpdated(address indexed account, string profileURI);
	event NFTRegistered(address indexed account);
	event NFTDeRegistered(address indexed account);
	event ContractAvatarCreated(address indexed account, string avatarURI);
	event ContractAvatarUpdated(address indexed account, string avatarURI);
	event ContractProfileCreated(address indexed account, string profileURI);
	event ContractProfileUpdated(address indexed account, string profileURI);
	event ServiceDonated(address indexed account, uint256 amount);

	string public baseURI = "https://ipfs.io/ipfs/";
	mapping(address => uint256) private donations;
	mapping(address => string) private avatars;
	mapping(address => string) private profiles;
	mapping(address => AvatarNFT) public avatarNFTs;
	mapping(address => bool) public contracts;

	constructor() ERC20("Blockchain Registered Avatar", "BCRA") {}

	function getAvatar(address account) public view returns (string memory) {
		if (avatarNFTs[account].nft != address(0)) {
			address nft = avatarNFTs[account].nft;
			uint256 tokenId = avatarNFTs[account].tokenId;
			if (avatarNFTs[account].isERC721) {
				if (IERC721(nft).ownerOf(tokenId) == account) {
					return IERC721Metadata(nft).tokenURI(tokenId);
				}
			} else {
				if (IERC1155(nft).balanceOf(account, tokenId) > 0) {
					return IERC1155MetadataURI(nft).uri(tokenId);
				}
			}
		}
		if (bytes(avatars[account]).length > 0) {
			return string(abi.encodePacked(baseURI, avatars[account]));
		} else {
			return "";
		}
	}

	function setAvatar(string memory avatarHash) public {
		bool notCreated = bytes(avatars[msg.sender]).length == 0;
		avatars[msg.sender] = avatarHash;
		if (notCreated) {
			emit AvatarCreated(msg.sender, getAvatar(msg.sender));
		} else {
			emit AvatarUpdated(msg.sender, getAvatar(msg.sender));
		}
	}

	function getProfile(address account) public view returns (string memory) {
		if (bytes(profiles[account]).length > 0) {
			return string(abi.encodePacked(baseURI, profiles[account]));
		} else {
			return "";
		}
	}

	function setProfile(string memory profileHash) public {
		bool notCreated = bytes(profiles[msg.sender]).length == 0;
		profiles[msg.sender] = profileHash;
		if (notCreated) {
			emit ProfileCreated(msg.sender, getProfile(msg.sender));
		} else {
			emit ProfileUpdated(msg.sender, getProfile(msg.sender));
		}
	}

	function registerNFT(
		address nft,
		uint256 tokenId,
		bool isERC721
	) public {
		if (isERC721) {
			require(IERC721(nft).ownerOf(tokenId) == msg.sender, "Owner invalid");
		} else {
			require(IERC1155(nft).balanceOf(msg.sender, tokenId) > 0, "Balance insufficient");
		}
		avatarNFTs[msg.sender] = AvatarNFT(nft, tokenId, isERC721);
		emit NFTRegistered(msg.sender);
	}

	function deRegisterNFT() public {
		require(avatarNFTs[msg.sender].nft != address(0), "NFT not registered");
		delete avatarNFTs[msg.sender];
		emit NFTDeRegistered(msg.sender);
	}

	function setContractAvatar(address account, string memory avatarHash) public onlyOwner {
		require(Address.isContract(account), "Contract invalid");
		bool notCreated = bytes(avatars[account]).length == 0;
		avatars[account] = avatarHash;
		if (notCreated) {
			contracts[account] = true;
			emit ContractAvatarCreated(account, getAvatar(account));
		} else {
			emit ContractAvatarUpdated(account, getAvatar(account));
		}
	}

	function setOwnableContractAvatar(address account, string memory avatarHash) public {
		require(Ownable(account).owner() == msg.sender, "Owner invalid");
		bool notCreated = bytes(avatars[account]).length == 0;
		avatars[account] = avatarHash;
		if (notCreated) {
			contracts[account] = true;
			emit ContractAvatarCreated(account, getAvatar(account));
		} else {
			emit ContractAvatarUpdated(account, getAvatar(account));
		}
	}

	function setContractProfile(address account, string memory profileHash) public onlyOwner {
		require(Address.isContract(account), "Contract invalid");
		bool notCreated = bytes(profiles[account]).length == 0;
		profiles[account] = profileHash;
		if (notCreated) {
			contracts[account] = true;
			emit ContractProfileCreated(account, getProfile(account));
		} else {
			emit ContractProfileUpdated(account, getProfile(account));
		}
	}

	function setOwnableContractProfile(address account, string memory profileHash) public {
		require(Ownable(account).owner() == msg.sender, "Owner invalid");
		bool notCreated = bytes(profiles[account]).length == 0;
		profiles[account] = profileHash;
		if (notCreated) {
			contracts[account] = true;
			emit ContractProfileCreated(account, getProfile(account));
		} else {
			emit ContractProfileUpdated(account, getProfile(account));
		}
	}

	function donate() public payable {
		require(msg.value > 0, "Donation insufficient");
		super._mint(msg.sender, msg.value);
		donations[msg.sender] += msg.value;
		emit ServiceDonated(msg.sender, msg.value);
	}

	function withdraw() public onlyOwner {
		require(address(this).balance > 0, "Amount insufficient");
		payable(owner()).transfer(address(this).balance);
	}
}
