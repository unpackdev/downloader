// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

// import "./console.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract CCML is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant tokenPrice = 200000000000000000 wei; // 0.2 ETH
    // uint256 public constant tokenPrice = 200000000000; // 0.00002 ETH price for testing
    uint256 public maxNftSupply = 10000;

    bool public publicSale = false;

    string public _baseURIextended = "ipfs://QmeGRGymLZus4bThvyUnQeGD2SWREZTZuPrsGddepKPnvA/";
    string public baseExtension = ".json";

    // WhiteLists for presale.
    mapping(address => bool) private _whitelist;
    mapping(uint256 => bool) private _minted;

    constructor() payable ERC721("CRYPTOCAMEL", "CCML") {
        _whitelist[msg.sender] = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "CCML: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension));
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        _baseURIextended = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function flipPublicMinting() external onlyOwner {
        publicSale = !publicSale;
    }

    function airdrop(uint256[] memory _ids, address[] memory _owners) external payable onlyOwner {
        require(_ids.length > 0 && _owners.length > 0, "CCML: must provide at least one token and owner");
        require(_ids.length == _owners.length, "CCML: ids and owners must have the same length");

        // verify the tokens exist first
        for (uint256 i = 0; i < _ids.length; i++) {
            require(_minted[_ids[i]] == false, "CCML: One or more of these ids are taken");
            require(
                _ids[i] <= maxNftSupply,
                "CCML: One or more of these ids are greater than the max number of tokens"
            );
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            _minted[_ids[i]] = true;
            _safeMint(_owners[i], _ids[i]);
        }
    }

    function presaleMint(uint256[] memory _ids) external payable {
        uint256 numTokens = _ids.length;
        // require(numTokens > 0, "CCML: Must supply positive number for tokens to mint");
        // require(totalSupply() + numTokens <= maxNftSupply, "CCML: Purchase would exceed max supply of tokens");
        require(_whitelist[msg.sender] == true, "CCML: sender is not whitelisted for presale");
        require(tokenPrice * numTokens <= msg.value, "CCML: Insufficient funds sent for purchase");
        require((totalSupply() + numTokens) <= maxNftSupply, "CCML: Mint would exceed max supply of tokens");

        // for (uint256 i = 0; i < numTokens; i++) {
        //     // mints a new token right off the top of the supply
        //     _minted[totalSupply()] = true;
        //     _safeMint(msg.sender, totalSupply());
        // }

        // verify the tokens exist first
        for (uint256 i = 0; i < numTokens; i++) {
            require(_minted[_ids[i]] == false, "CCML: One or more of these ids are taken");
            require(
                _ids[i] <= maxNftSupply,
                "CCML: One or more of these ids are greater than the max number of tokens"
            );
        }

        for (uint256 i = 0; i < numTokens; i++) {
            if (totalSupply() < maxNftSupply) {
                _minted[_ids[i]] = true;
                _safeMint(msg.sender, _ids[i]);
            }
        }
    }

    function mint(uint256[] memory _ids) external payable {
        uint256 numTokens = _ids.length;
        require(publicSale, "CCML: Public sales aren't available yet");
        require((tokenPrice * numTokens) <= msg.value, "CCML: Insufficient funds sent for purchase");
        require((totalSupply() + numTokens) <= maxNftSupply, "CCML: Mint would exceed max supply of tokens");

        // verify the tokens exist first
        for (uint256 i = 0; i < numTokens; i++) {
            require(_minted[_ids[i]] == false, "CCML: One or more of these ids are taken");
            require(
                _ids[i] <= maxNftSupply,
                "CCML: One or more of these ids are greater than the max number of tokens"
            );
        }

        for (uint256 i = 0; i < numTokens; i++) {
            if (totalSupply() < maxNftSupply) {
                _minted[_ids[i]] = true;
                _safeMint(msg.sender, _ids[i]);
            }
        }
    }

    function whitelistAdd(address[] memory _wallets) external onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            _whitelist[_wallets[i]] = true;
        }
    }

    function whitelistRemove(address[] memory _wallets) external onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            _whitelist[_wallets[i]] = false;
        }
    }

    function withdraw() external payable onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    fallback() external payable {}

    receive() external payable {}
}
