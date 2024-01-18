// SPDX-License-Identifier: MIT
import "./ERC721AQueryableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSA.sol";

pragma solidity ^0.8.4;

contract NBean is ERC721AQueryableUpgradeable, OwnableUpgradeable {
	address public signer;
	string public baseTokenURI;
	uint8 public phase;
	uint256 public maxSupply;
	uint256 public maxBalancePerWallet;

	function _baseURI() override internal view virtual returns (string memory) {
        return baseTokenURI;
    }

	function initialize(address s, string memory baseURI, uint256 ms, uint256 mbpw) initializerERC721A initializer public {
		__ERC721A_init("9Bean", "9Bean");
		__Ownable_init();
		baseTokenURI = baseURI;
		signer = s;
		maxSupply = ms;
		maxBalancePerWallet = mbpw;
	}

	function checkWhitelistEligibility(bytes calldata signature)
		public
		view
		returns (bool)
	{
		require(ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender))), signature) == signer, "wrong signature");
		return true;
	}

	modifier whenWhitelistStarted() {
		require(phase == 0, "invalid phase");
		_;
	}

	modifier whenPublicStarted() {
		require(phase == 1, "invalid phase");
		_;
	}

	function mintWhitelist(
		bytes calldata signature
	) external payable whenWhitelistStarted {
		require(totalSupply() < maxSupply, "All minted");
		require(balanceOf(msg.sender) < maxBalancePerWallet, "Minted");
		checkWhitelistEligibility(signature);
		_mint(msg.sender, 1);
	}

	function mint() external whenPublicStarted {
		require(totalSupply() < maxSupply, "All minted");
		require(balanceOf(msg.sender) < maxBalancePerWallet, "Minted");
		_mint(msg.sender, 1);
	}

	function setPhase(uint8 p) external onlyOwner {
		phase = p;
	}

	function setBaseURL(string calldata b) external onlyOwner {
		baseTokenURI = b;
	}

	function airdrop(address[] memory addrs, uint256[] memory counts) external onlyOwner {
		require(addrs.length == counts.length);
		for (uint i = 0; i < addrs.length; i++) {
			_mint(addrs[i], counts[i]);
		}
		if (totalSupply() > maxSupply) {
			maxSupply = totalSupply();
		}
	}

	function setMaxSupply(uint256 p) external onlyOwner {
		maxSupply = p;
	}
}
