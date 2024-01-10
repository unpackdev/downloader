//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC721A.sol";

contract MetaGecko is ERC721A, Ownable {
    using Strings for uint256;

    string private baseTokenURI;
    string private notRevealedUri;
    uint256 public cost = 0.1 ether;
    uint256 public insectCost = 20 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxByWallet = 4;
    bool public paused = true;
    bool public revealed = false;
    address payable private devguy = payable(0x5C3229ef0c9A4219D226dE5cA2c14C7FAA175799);

    address public insectContract;
    address public metaLezardsContract;

    mapping(uint => bool) public isBreed;
    mapping (uint => bool) public Genesis;
    mapping(address => uint) public numberMinted;

    constructor() ERC721A("Metageckos", "MG") {}

    function mintMetaGecko(uint256 _amount) public payable {
        require(!paused, "the mint is paused");
        require(totalSupply() + _amount <= maxSupply, "Sold out !");
        require(
            numberMinted[msg.sender] + _amount <= maxByWallet,
            "You have exceeded the maximum number of NFT per wallet minter with ETH"
        );
        require(msg.value >= cost * _amount, "Not enough ether sended");
        numberMinted[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function breedMetaGecko(uint256 metaLizards1, uint256 metaLizards2) public payable {
        require(!paused, "the mint is paused");
        require(totalSupply() + 1 <= maxSupply, "Sold out !");
        require(getBalanceInsect(msg.sender) >= insectCost, "Not enough insect sended");
        require(!Genesis[metaLizards1] && !Genesis[metaLizards2], "This lizard is a genesis");
        require(metaLizards1 != metaLizards2, "You must choose 2 different lizards");
        require(!isBreed[metaLizards1] && !isBreed[metaLizards2], "this lizard has already been breed");
        require(getLezardsOwner(metaLizards1) == msg.sender && getLezardsOwner(metaLizards2) == msg.sender, "Not the owner of this Lezards");
        IERC20(insectContract).transferFrom(msg.sender, address(this), insectCost);
        isBreed[metaLizards1] = true;
        isBreed[metaLizards2] = true;
        _safeMint(msg.sender, 1);
    }

    function breedMetaGeckoGenesis(uint256 genesisId) public payable {
        require(!paused, "the mint is paused");
        require(totalSupply() + 1 <= maxSupply, "Sold out !");
        require(getBalanceInsect(msg.sender) >= insectCost, "Not enough insect sended");
        require(Genesis[genesisId], "This lizard is not a genesis");
        require(getLezardsOwner(genesisId) == msg.sender, "Not the owner of this genesis");
        require(!isBreed[genesisId], "this lizard has already been breed");
        IERC20(insectContract).transferFrom(msg.sender, address(this), insectCost);
        isBreed[genesisId] = true;
        _safeMint(msg.sender, 1);
    }

    // MetaGecko Checker (by Silver.btc)

    function getBalanceInsect(address _owner) public view returns (uint) {
        return IERC20(insectContract).balanceOf(_owner);
    }

    function getLezardsOwner(uint256 _metaLizardsID) public view returns (address) {
        return IERC721(metaLezardsContract).ownerOf(_metaLizardsID);
    }

    function checkIsBreed(uint256 _LizardsID) public view returns (bool) {
        return isBreed[_LizardsID];
    }

    function setInsectContract(address _insect) public onlyOwner {
        insectContract = _insect;
    }

    function setMetaLezardsContract(address _lezards) public onlyOwner {
        metaLezardsContract = _lezards;
    }

    function addGenesis(uint[] memory _Genesis) public onlyOwner {
        for (uint256 i = 0; i < _Genesis.length; i++) {
            Genesis[_Genesis[i]] = true;
        }
    }

    function removeGenesis(uint[] memory _Genesis) public onlyOwner {
        for (uint256 i = 0; i < _Genesis.length; i++) {
            Genesis[_Genesis[i]] = false;
        }
    }

    function addBreed(uint[] memory _lezardsId) public onlyOwner {
        for (uint256 i = 0; i < _lezardsId.length; i++) {
            isBreed[_lezardsId[i]] = true;
        }
    }

    function removeBreed(uint[] memory _lezardsId) public onlyOwner {
        for (uint256 i = 0; i < _lezardsId.length; i++) {
            isBreed[_lezardsId[i]] = false;
        }
    }

    function gift(uint256 _amount, address _to) public onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Sold out");
        _safeMint(_to, _amount);
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setCost(uint256 newCost) public onlyOwner {
        cost = newCost;
    }

    function setMaxByWallet(uint256 _newMaxByWallet) public onlyOwner {
        maxByWallet = _newMaxByWallet;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function _baseUri() internal view virtual returns (string memory) {
        return baseTokenURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseUri();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdraw() external onlyOwner {
        uint part = address(this).balance / 100 * 5;
        devguy.transfer(part);
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawInsect(uint _amount) external onlyOwner {
        IERC20(insectContract).transfer(msg.sender, _amount);
    }
}