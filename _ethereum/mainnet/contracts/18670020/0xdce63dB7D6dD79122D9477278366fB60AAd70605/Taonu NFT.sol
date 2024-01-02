// SPDX-License-Identifier: MIT


// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B7~&@@@@@@@@@@@@@@@@G!:&@@@@@@@@@@@@@@@&5~.&@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P~    P@@@@@@@@@@@@&Y^    G@@@@@@@@@@@@#J:    G@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#J:       G@@@@@@@@@B7.       G@@@@@@@@&G!.       G@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@G!.          G@@@@@&P~           B@@@@@&Y:           G@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@&Y^              ~&&#J:              ^#&B7.              G@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@#7.                                                         &@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@G                                                         ^5&@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@J              ^5&@&:              ~P&@&:             .7B@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@J          .!G@@@@@@J          .?B@@@@@@J          :Y#@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@J       :J#@@@@@@@@@J       ^5&@@@@@@@@@?      .~P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@J    ~P&@@@@@@@@@@@@J   .7B@@@@@@@@@@@@@?   :?#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@B^?B@@@@@@@@@@@@@@@@B~J#@@@@@@@@@@@@@@@@#!5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//
//          Telegram: t.me/TaoInu
//          Twitter:  twitter.com/taoinuerc20
//          Website:  https://taonu.vip
//

pragma solidity ^0.8.7;

import "./ERC721EnumerableUpgradeable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";

contract TaonuNFT is Initializable, ERC721EnumerableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
	using CountersUpgradeable for CountersUpgradeable.Counter;
	using StringsUpgradeable for uint256;

	bool public paused;
	bool public revealed;

	string private unrevealedURI;
	string private baseURI;
	string private uriSuffix;

	uint256 public price;
	uint256 public maxSupply;
    
    uint256 public startTime;

	CountersUpgradeable.Counter private supply;

	function initialize(uint256 _startTime) public initializer {
		__ERC721_init("Tao Inu AI", "TAONUAI");
		__ERC721Enumerable_init();
		__Ownable_init();
		paused = false;
		revealed = false;

		price = 0.1 ether;
		maxSupply = 50;

        startTime = _startTime;

		setURIsuffix(".json");
		setUnrevealedURI("ipfs://");
	}

	function mint(uint256 amount) external payable nonReentrant {
        require(isMintingSeason(), "Minting has not been started.");

		uint256 newSupply = supply.current() + amount;

		require(newSupply <= maxSupply, "Max token supply exceeded");

		require(!paused, "Minting is paused");

		uint256 proceeds = 0;
        proceeds = price * amount;
		require(msg.value >= proceeds, "Insufficient funds");

		_mintLoop(_msgSender(), amount);
	}

	function isMintingSeason() public view returns(bool) {
		return block.timestamp >= startTime;
	}

	function flipPausedState() external onlyOwner {
		paused = !paused;
	}

	function reveal(string memory _initBaseURI) external onlyOwner {
		revealed = true;

		setBaseURI(_initBaseURI);
	}

	function withdraw() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function tokenURI(uint256 tokenID) public view override returns(string memory) {
		require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

		if (!revealed) return unrevealedURI;

		string memory currentBaseURI = _baseURI();

		return bytes(currentBaseURI).length > 0 ? string( abi.encodePacked(currentBaseURI, tokenID.toString(), uriSuffix) ) : "";
	}

	function walletOfOwner(
        address _owner
    ) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

	function setStartTime(uint256 _startTime) external onlyOwner {
		startTime = _startTime;
	}

	function setBaseURI(string memory newBaseURI) public onlyOwner {
		baseURI = newBaseURI;
	}

	function setUnrevealedURI(string memory newUnrevealedURI) public onlyOwner {
		unrevealedURI = newUnrevealedURI;
	}

	function setURIsuffix(string memory newSuffix) public onlyOwner {
		uriSuffix = newSuffix;
	}

	function setMaxSupply(uint256 newAmount) public onlyOwner {
		maxSupply = newAmount;
	}

	function setPrice(uint256 newPrice) public onlyOwner {
		price = newPrice;
	}

	function _baseURI() internal view override returns(string memory) {
		return baseURI;
	}

	function _mintLoop(address to, uint256 amount) internal {
		for (uint256 i = 0; i < amount; i++) {
			supply.increment();

			_safeMint(to, supply.current());
		}
	}
}