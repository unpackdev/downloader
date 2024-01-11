// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Inverse is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private plan1Counter;
    Counters.Counter private plan2Counter;
    Counters.Counter private plan3Counter;
    Counters.Counter private plan4Counter;
    Counters.Counter private plan5Counter;
    Counters.Counter private plan6Counter;
    Counters.Counter private plan7Counter;
    Counters.Counter private plan8Counter;

    uint256 public plan1Price = 1 ether;
    uint256 public plan2Price = 1.5 ether;
    uint256 public plan3Price = 2 ether;
    uint256 public plan4Price = 2.5 ether;
    uint256 public plan5Price = 2.5 ether;
    uint256 public plan6Price = 3 ether;
    uint256 public plan7Price = 4 ether;
    uint256 public plan8Price = 5 ether;

    uint256 public plan1MaxSupply = 20;
    uint256 public plan2MaxSupply = 2;
    uint256 public plan3MaxSupply = 5;
    uint256 public plan4MaxSupply = 8;
    uint256 public plan5MaxSupply = 5;
    uint256 public plan6MaxSupply = 7;
    uint256 public plan7MaxSupply = 1;
    uint256 public plan8MaxSupply = 1;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public maxSupply = 49;

    bool public paused = false;

    constructor() ERC721("Inverse by HomeStart", "Inverse") {}

    function mintPlan1(address _to) public payable {
        require(
            totalSupplyPlan1() < plan1MaxSupply,
            "minting this many would exceed supply"
        );
        require(msg.value >= plan1Price, "not enough ether sent");
        require(!paused, "contract is paused");
        uint256 tokenId = plan1Counter.current() + 1;
        plan1Counter.increment();
        _safeMint(_to, tokenId);
    }

    function mintPlan2(address _to) public payable {
        require(
            totalSupplyPlan2() < plan2MaxSupply,
            "minting this many would exceed supply"
        );
        require(msg.value >= plan2Price, "not enough ether sent");
        require(!paused, "contract is paused");
        uint256 tokenId = plan2Counter.current() + 1 + 20;
        plan2Counter.increment();
        _safeMint(_to, tokenId);
    }

    function mintPlan3(address _to) public payable {
        require(
            totalSupplyPlan3() < plan3MaxSupply,
            "minting this many would exceed supply"
        );
        require(msg.value >= plan3Price, "not enough ether sent");
        require(!paused, "contract is paused");
        uint256 tokenId = plan3Counter.current() + 1 + 20 + 2;
        plan3Counter.increment();
        _safeMint(_to, tokenId);
    }

    function mintPlan4(address _to) public payable {
        require(
            totalSupplyPlan4() < plan4MaxSupply,
            "minting this many would exceed supply"
        );
        require(msg.value >= plan4Price, "not enough ether sent");
        require(!paused, "contract is paused");
        uint256 tokenId = plan4Counter.current() + 1 + 20 + 2 + 5;
        plan4Counter.increment();
        _safeMint(_to, tokenId);
    }

    function mintPlan5(address _to) public payable {
        require(
            totalSupplyPlan5() < plan5MaxSupply,
            "minting this many would exceed supply"
        );
        require(msg.value >= plan5Price, "not enough ether sent");
        require(!paused, "contract is paused");
        uint256 tokenId = plan5Counter.current() + 1 + 20 + 2 + 5 + 8;
        plan5Counter.increment();
        _safeMint(_to, tokenId);
    }

    function mintPlan6(address _to) public payable {
        require(
            totalSupplyPlan6() < plan6MaxSupply,
            "minting this many would exceed supply"
        );
        require(msg.value >= plan6Price, "not enough ether sent");
        require(!paused, "contract is paused");
        uint256 tokenId = plan6Counter.current() + 1 + 20 + 2 + 5 + 8 + 5;
        plan6Counter.increment();
        _safeMint(_to, tokenId);
    }

    function mintPlan7(address _to) public payable {
        require(
            totalSupplyPlan7() < plan7MaxSupply,
            "minting this many would exceed supply"
        );
        require(msg.value >= plan7Price, "not enough ether sent");
        require(!paused, "contract is paused");
        uint256 tokenId = plan7Counter.current() + 1 + 20 + 2 + 5 + 8 + 5 + 7;
        plan7Counter.increment();
        _safeMint(_to, tokenId);
    }

    function mintPlan8(address _to) public payable {
        require(
            totalSupplyPlan8() < plan8MaxSupply,
            "minting this many would exceed supply"
        );
        require(msg.value >= plan8Price, "not enough ether sent");
        require(!paused, "contract is paused");
        uint256 tokenId = plan8Counter.current() +
            1 +
            20 +
            2 +
            5 +
            8 +
            5 +
            7 +
            1;
        plan8Counter.increment();
        _safeMint(_to, tokenId);
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

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw(address _addr) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }

    function totalSupplyPlan1() public view returns (uint256) {
        return plan1Counter.current();
    }

    function totalSupplyPlan2() public view returns (uint256) {
        return plan2Counter.current();
    }

    function totalSupplyPlan3() public view returns (uint256) {
        return plan3Counter.current();
    }

    function totalSupplyPlan4() public view returns (uint256) {
        return plan4Counter.current();
    }

    function totalSupplyPlan5() public view returns (uint256) {
        return plan5Counter.current();
    }

    function totalSupplyPlan6() public view returns (uint256) {
        return plan6Counter.current();
    }

    function totalSupplyPlan7() public view returns (uint256) {
        return plan7Counter.current();
    }

    function totalSupplyPlan8() public view returns (uint256) {
        return plan8Counter.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
