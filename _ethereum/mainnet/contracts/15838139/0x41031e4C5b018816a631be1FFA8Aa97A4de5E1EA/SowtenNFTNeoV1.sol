//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract SowtenNFTNeoV1 is ERC721A, Ownable {
    using Strings for uint256;
    
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 5;
    uint256 public salePeriod = 1;
    bool public paused = false;
    /* mint num on salePeriod */
    mapping(address => uint[10]) public whitelisted;
    mapping(address => uint[10]) public mintAmount;
    /* presale price on salePeriod */
    mapping(uint => uint256) public price;
    mapping(uint => uint256) public totalSupplyOnPeriod;
    mapping(uint => uint256) public maxSupplyOnPeriod;
    mapping(uint => bool) public anyoneCanMint;
    mapping(uint => uint256) public anyoneCanMintNum;

    constructor() ERC721A("SOWTEN", "Agent") {
        price[0] = 0.08 ether;
        price[1] = 0.05 ether;  // PL1
        maxSupplyOnPeriod[0] = maxSupply;
        maxSupplyOnPeriod[1] = 750; // SL1
        anyoneCanMint[0] = true;
        anyoneCanMint[1] = false;
        anyoneCanMintNum[0] = 1;
        anyoneCanMintNum[1] = 0;
        mintOnPeriod(msg.sender, 1, 0);
    }

    /* internal */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /* public */
    function mint(address _to, uint256 _mintAmount) public payable {
        mintOnPeriod(_to, _mintAmount, salePeriod);
    }

    function publicMint(address _to, uint256 _mintAmount, uint256 _salePeriod) public payable {
        mintOnPeriod(_to, _mintAmount, _salePeriod);
    }

    function mintOnPeriod(address _to, uint256 _mintAmount, uint256 _salePeriod) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            require(_mintAmount <= maxMintAmount, "The mint num has been exceeded.(Total)");
            require(totalSupplyOnPeriod[_salePeriod] + _mintAmount <= maxSupplyOnPeriod[_salePeriod], "The mint num has been exceeded.(On Period)");
            require(msg.value >= price[_salePeriod] * _mintAmount, "The price is incorrect."); // price

            if(_salePeriod != 0) { 
                if((anyoneCanMint[_salePeriod] == true)) {
                    // anyone mint
                    if(anyoneCanMintNum[_salePeriod] == 0) {
                        revert("Not permitted to mint during this sales period.");
                    }
                    if(_mintAmount + mintAmount[msg.sender][_salePeriod] > anyoneCanMintNum[_salePeriod]) {
                        revert("Exceeded the number of mints permitted for this sales period.");
                    }
                } else {
                    // whitelist mint
                    if(whitelisted[msg.sender][_salePeriod] == 0) {
                        revert("Not permitted to mint during this sales period.");
                    }
                    if(_mintAmount + mintAmount[msg.sender][_salePeriod] > whitelisted[msg.sender][_salePeriod]) {
                        revert("Exceeded the number of mints permitted for this sales period.");
                    }
                }
            }
        }

        // Mint Method (ERC721A)
        _safeMint(_to, _mintAmount);
        mintAmount[_to][_salePeriod] = mintAmount[_to][_salePeriod] + _mintAmount;
        totalSupplyOnPeriod[_salePeriod] = totalSupplyOnPeriod[_salePeriod] + _mintAmount;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function getPriceOnPeriod(uint256 _salePeriod) public view returns(uint256){
        return price[_salePeriod];
    }

    function getWhitelistUserOnPeriod(address _user, uint256 _salePeriod) public view returns(uint256) {
        return whitelisted[_user][_salePeriod];
    }

    function getMintAmountOnPeriod(address _user, uint256 _salePeriod) public view returns(uint256) {
        return mintAmount[_user][_salePeriod];
    }

    function getTotalSupplyOnPeriod(uint256 _salePeriod) public view returns(uint256) {
        return totalSupplyOnPeriod[_salePeriod];
    }

    function getMaxSupplyOnPeriod(uint256 _salePeriod) public view returns(uint256) {
        return maxSupplyOnPeriod[_salePeriod];
    }

    function getAnyoneCanMint(uint256 _salePeriod) public view returns(bool) {
        return anyoneCanMint[_salePeriod];
    }

    function getAnyoneCanMintNum(uint256 _salePeriod) public view returns(uint256) {
        return anyoneCanMintNum[_salePeriod];
    }

    /* only owner */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setSalePeriod(uint256 _salePeriod) public onlyOwner {
        salePeriod = _salePeriod;
    }

    function setPriceOnPeriod(uint256 _salePeriod, uint256 _price) public onlyOwner {
        price[_salePeriod] = _price;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setMaxSupplyOnPeriod(uint256 _salePeriod, uint256 _maxSupplyOnPeriod) public onlyOwner {
        maxSupplyOnPeriod[_salePeriod] = _maxSupplyOnPeriod;
    }

    function setAnyoneCanMint(uint256 _salePeriod, bool _anyoneCanMint) public onlyOwner {
        anyoneCanMint[_salePeriod] = _anyoneCanMint;
    }

    function setAnyoneCanMintNum(uint256 _salePeriod, uint256 _anyoneCanMintNum) public onlyOwner {
        anyoneCanMintNum[_salePeriod] = _anyoneCanMintNum;
    }

    function addWhitelistUserOnPeriod(address _user, uint256 _mintNum, uint256 _salePeriod) public onlyOwner {
        whitelisted[_user][_salePeriod] = _mintNum;
    }

    function addWhitelistUserOnPeriodBulk(address[] memory _users, uint256 _mintNum, uint256 _salePeriod) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelisted[_users[i]][_salePeriod] = _mintNum;
        }
    }

    function removeWhitelistUserOnPeriod(address _user, uint256 _salePeriod) public onlyOwner {
        whitelisted[_user][_salePeriod] = 0;
    }

    function airdropNfts(address[] calldata wAddresses) public onlyOwner {
        for (uint i = 0; i < wAddresses.length; i++) {
            _safeMint(wAddresses[i], 1);
        }
        totalSupplyOnPeriod[0] = totalSupplyOnPeriod[0] + wAddresses.length;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function burn(uint256 tokenId, bool approvalCheck) public onlyOwner {
        _burn(tokenId, approvalCheck);
    }

    //send remaining NFTs to walet
    function devMint(uint256 _totalSupply) external onlyOwner {
        address user = owner(); 
        uint256 leftOver = _totalSupply - totalSupply();
        while (leftOver > 10) {
            _safeMint(user, 10);
            leftOver -= 10;
        }
        if (leftOver > 0) {
            _safeMint(user, leftOver);
        }
    }
}
