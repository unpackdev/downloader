// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./console.sol";

/// @custom:security-contact security@nonfungibleunit.io
contract Pysanka is ERC721, Ownable {
    using Counters for Counters.Counter;

    bool private reentrancyGuard;

    uint public immutable supplyCap = 10_000;
    uint public immutable tokenPrice = 0.0380 ether;
    uint public numberOfBeneficiaries;
    uint private teamSize;

    mapping(uint => Beneficiary) public beneficiaries;
    mapping(uint => address payable) private team;

    struct Beneficiary{
        address payable beneficiary;
        string title;
    }

    Counters.Counter private _tokenIdCounter;

    event NewBeneficiary(
        address indexed beneficiary,
        string title,
        uint currentNumberOfBeneficiaries
    );

    constructor(address[] memory initialHodlers, address[] memory _team) ERC721("Pysanka", "PYS") {
        for(uint i = 0; i < initialHodlers.length; i++){
            require(safeMint(initialHodlers[i]), "Pysanka: initailMint failed");
        }
        for(uint j = 0; j < _team.length; j++){
            team[j] = payable(_team[j]);
        }
        teamSize = _team.length;
    }

    modifier reentrancyProtection(){
        require(!reentrancyGuard, "Pysanka: reentrancyGuard");
        reentrancyGuard = true;
        _;
        reentrancyGuard = false;
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    function addBeneficiary(address payable _beneficiary, string memory _title) public onlyOwner {
        require(_beneficiary != address(0x0), "Pysanka: _beneficiary is 0x0 address");
        require(
            keccak256(abi.encodePacked(_title)) != keccak256(abi.encodePacked("")),
            "Pysanka: _title is empty string"
        );
        beneficiaries[numberOfBeneficiaries].beneficiary = _beneficiary;
        beneficiaries[numberOfBeneficiaries].title = _title;
        numberOfBeneficiaries += 1;
        emit NewBeneficiary(_beneficiary, _title, numberOfBeneficiaries);
    }

    function saleMint() public payable returns(bool){
        require(_tokenIdCounter.current() < supplyCap, "Pysanka: supplyCap reached");
        require(tokenPrice <= msg.value, "Pysanka: not enough Ether to buy token");
        require(msg.value/tokenPrice <= 100, "Pysanka: can only mint 100 tokens in one transaction");
        require(
            _tokenIdCounter.current() + msg.value/tokenPrice <= supplyCap,
            "Pysanka: minting this amount would surpass supply cap"
        );
        for(uint i = 0; i < msg.value/tokenPrice; i++){
            require(safeMint(msg.sender), "Pysanka: saleMint failed");
        }
        require(allocateFunds(), "Pysanka: failed to allocate funds");
        return true;
    }

    function safeMint(address to) internal returns(bool) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        return true;
    }

    function allocateFunds() internal reentrancyProtection returns(bool) {
        uint humanitarianFunds = msg.value / 10 * 9;
        uint maintenanceFunds = msg.value - humanitarianFunds;

        for(uint i = 0; i < numberOfBeneficiaries; i++){
            beneficiaries[i].beneficiary.transfer(humanitarianFunds/numberOfBeneficiaries);
        }

        team[0].transfer(maintenanceFunds - (maintenanceFunds / 100 * 5 * (teamSize - 1)));
        for(uint j = 1; j < teamSize; j++){
            team[j].transfer(maintenanceFunds / 100 * 5);
        }
        return true;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://pysanka.xyz/tokens/metadata/";
    }

    fallback() external payable {
        require(saleMint(), "Pysanka: saleMintfailed");
    }

    receive() external payable {
        require(saleMint(), "Pysanka: saleMintfailed");
    }
}