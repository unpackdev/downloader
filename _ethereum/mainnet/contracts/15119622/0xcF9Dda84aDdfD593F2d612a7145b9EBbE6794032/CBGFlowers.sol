pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
/*
      _______    _______     .-_'''-.
     /   __  \  \  ____  \  '_( )_   \
    | ,_/  \__) | |    \ | |(_ o _)|  '
  ,-./  )       | |____/ / . (_,_)/___|
  \  '_ '`)     |   _ _ '. |  |  .-----.
   > (_)  )  __ |  ( ' )  \'  \  '-   .'
  (  .  .-'_/  )| (_{;}_) | \  `-'`   |
   `-'`-'     / |  (_,_)  /  \        /
     `._____.'  /_______.'    `'-...-'
   ________   .---.       ,-----.    .--.      .--.    .-''-.  .-------.       .-'''-.
  |        |  | ,_|     .'  .-,  '.  |  |_     |  |  .'_ _   \ |  _ _   \     / _     \
  |   .----',-./  )    / ,-.|  \ _ \ | _( )_   |  | / ( ` )   '| ( ' )  |    (`' )/`--'
  |  _|____ \  '_ '`) ;  \  '_ /  | :|(_ o _)  |  |. (_ o _)  ||(_ o _) /   (_ o _).
  |_( )_   | > (_)  ) |  _`,/ \ _/  || (_,_) \ |  ||  (_,_)___|| (_,_).' __  (_,_). '.
  (_ o._)__|(  .  .-' : (  '\_/ \   ;|  |/    \|  |'  \   .---.|  |\ \  |  |.---.  \  :
  |(_,_)     `-'`-'|___\ `"/  \  ) / |  '  /\  `  | \  `-'    /|  | \ `'   /\    `-'  |
  |   |       |        \'. \_/``".'  |    /  \    |  \       / |  |  \    /  \       /
  '---'       `--------`  '-----'    `---'    `---`   `'-..-'  ''-'   `'-'    `-...-'

 by Hidden Lotus Tech
*/
contract CBGFlowers is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    bool public paused;

    uint256 public constant maxSupply = 713;

    uint256 public maxMintAmountPerTx = 2;
    uint256 public reserveCount;
    uint256 public reserveLimit = 33;

    string public uriPrefix;
    string public uriSuffix;

    constructor(string memory _uriPrefix) ERC721("CBGFlowers", "CBGFLO") {
        uriPrefix = _uriPrefix;
        uriSuffix = ".json";
        reserveCount = 0;
        paused = true;
    }

    modifier mintCompliance(uint256 mintCount) {
        require(mintCount > 0, "Mint count must be greater than 0.");
        require(
            supply.current() + mintCount <= maxSupply,
            "Would exceed max supply."
        );
        require(
            supply.current() + mintCount <=
                maxSupply - (reserveLimit - reserveCount),
            "Exceeds max supply + reserve."
        );
        _;
    }

    modifier publicCompliance(uint256 mintCount) {
        require(!paused, "The sale is paused.");
        require(
            mintCount <= maxMintAmountPerTx,
            "Invalid mint amount. Extends transaction limit."
        );
        _;
    }

    function mint(uint256 mintCount)
        public
        mintCompliance(mintCount)
        publicCompliance(mintCount)
    {
        _mintLoop(msg.sender, mintCount);
    }

    function mintForAddress(uint256 mintCount, address _receiver)
        public
        mintCompliance(mintCount)
        onlyOwner
    {
        require(
            reserveCount + mintCount <= reserveLimit,
            "Exceeds max reserved."
        );
        _mintLoop(_receiver, mintCount);
        reserveCount += mintCount;
    }

    function _mintLoop(address _receiver, uint256 mintAmounts) internal {
        for (uint256 i = 0; i < mintAmounts; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token."
        );
        return
            bytes(uriPrefix).length > 0
                ? string(
                    abi.encodePacked(uriPrefix, _tokenId.toString(), uriSuffix)
                )
                : "INVALID";
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function setUriPrefix(string memory newUriPrefix) public onlyOwner {
        uriPrefix = newUriPrefix;
    }

    function setUriSuffix(string memory newUriSuffix) public onlyOwner {
        uriSuffix = newUriSuffix;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(msg.sender, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to widthdraw Ether");
    }
}
