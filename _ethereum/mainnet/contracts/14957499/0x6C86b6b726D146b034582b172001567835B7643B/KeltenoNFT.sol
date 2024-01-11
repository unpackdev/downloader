// SPDX-License-Identifier: MIT

/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

pragma solidity ^0.8.4;

// ░█─▄▀ ░█▀▀▀ ░█─── ▀▀█▀▀ ░█▀▀▀ ░█▄─░█ ░█▀▀▀█
// ░█▀▄─ ░█▀▀▀ ░█─── ─░█── ░█▀▀▀ ░█░█░█ ░█──░█
// ░█─░█ ░█▄▄▄ ░█▄▄█ ─░█── ░█▄▄▄ ░█──▀█ ░█▄▄▄█
//
//@custom:security-contact chakirberg.s@gmail.com
//
// ▒█▄░▒█ ▒█▀▀▀ ▀▀█▀▀
// ▒█▒█▒█ ▒█▀▀▀ ░▒█░░
// ▒█░░▀█ ▒█░░░ ░▒█░░
//
//@type: [Kelteno][Kelteno]
//
// ▒█▀▀▀ ▒█▀▀█ ▒█▀▀█ ▀▀▀█ █▀█ ▄█░
// ▒█▀▀▀ ▒█▄▄▀ ▒█░░░ ░░█░ ░▄▀ ░█░
// ▒█▄▄▄ ▒█░▒█ ▒█▄▄█ ░▐▌░ █▄▄ ▄█▄

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./PullPayment.sol";

contract KeltenoNFT is ERC721Enumerable, PullPayment, Ownable, ReentrancyGuard {
    struct TokenForSale {
        uint256 tokenId;
        uint256 price;
        bool isExist;
    }
    uint256 public nextAirdropId;
    mapping(uint256 => uint256) public airdrops;
    mapping(address => bool) public recipients;
    address[] public recipientsRegistry;
    mapping(address => bool) public mintRecipients;
    address[] public mintRecipientsRegistry;
    mapping(uint256 => TokenForSale) public forSale;
    uint256[] registeredForSale;
    string public baseTokenURI;

    uint256 public constant maxSupply = 888;
    uint256 public privateMintPrice = 0.025 ether;
    uint256 public keltenoMintValue = 0.00025 ether;
    uint256 public batchMax = 20;

    bool public privateMintingEnabled = false;
    bool public keltenoMintingEnabled = false;
    bool public tokenSellEnabled = false;
    bool public airDropClaimEnabled = false;
    bool public whitelistMintEnabled = false;

    bool public localConfig = false;
    bool public paymentsEnabled = false;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Kelteno", "KLTN") {
        _tokenIdCounter.increment();
        baseTokenURI = "ipfs://bafybeiecxfr3zho56oljevy24ueuojrjazvphevny2w4fegkwfomzfn7au/meta/";
    }

    /* ---------------------------- @KELTENO CONFIG -------------------------------*/

    function togglePrivateMinting() external onlyOwner {
        privateMintingEnabled = !privateMintingEnabled;
    }

    function toggleKeltenoMinting() external onlyOwner {
        keltenoMintingEnabled = !keltenoMintingEnabled;
    }

    function toggleWhiteListEnabled() external onlyOwner {
        whitelistMintEnabled = !whitelistMintEnabled;
    }

    function toggleAirDropClaimEnabled() external onlyOwner {
        airDropClaimEnabled = !airDropClaimEnabled;
    }

    function toggleTokenSell() external onlyOwner {
        tokenSellEnabled = !tokenSellEnabled;
    }

    function toggleLocalConfig() external onlyOwner {
        localConfig = !localConfig;
    }

    function togglePayments() external onlyOwner {
        paymentsEnabled = !paymentsEnabled;
    }

    function setBatchMaxNumber(uint256 batch) external onlyOwner {
        batchMax = batch;
    }

    function setPrivateMintingPrice(uint256 price) external onlyOwner {
        privateMintPrice = price;
    }

    function setKeltenoMintValue(uint256 price) external onlyOwner {
        keltenoMintValue = price;
    }

    /* ---------------------------- @KELTENO MIGRATION ------------------------------- */

    function migrate(address migrateTo) external onlyOwner {
        uint256[] memory owntokens = _getTokenIds();
        for(uint256 i = 0; i < owntokens.length; i++) {
             transferFrom(msg.sender, migrateTo, owntokens[i]);
        }
    }

    function getTokenIds(address _owner) external view  returns (uint[] memory) {
        require(localConfig, 'Local config is not enabled');
        uint[] memory _tokensOfOwner = new uint[](ERC721.balanceOf(_owner));
        for (uint i=0;i<ERC721.balanceOf(_owner);i++){
            _tokensOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(_owner, i);
        }
        return (_tokensOfOwner);
    }

    function _getTokenIds() private view returns (uint[] memory) {
        uint[] memory _tokensOfOwner = new uint[](ERC721.balanceOf(owner()));
        for (uint i=0; i<ERC721.balanceOf(owner()); i++){
            _tokensOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(owner(), i);
        }
        return (_tokensOfOwner);
    }

    /* ---------------------------- @KELTENO MINTERS ------------------------------- */

    function keltenoDrop(uint256 number, address to ,string memory tokenBaseUrl) external onlyOwner {
        require(number > 0 && number <= batchMax,string(abi.encodePacked("Machine can create a minimum of 1, maximum of ", Strings.toString(batchMax)," tokens")));
         for (uint256 i = 0; i < number; i++) { 
            uint256 tokenId = _tokenIdCounter.current();
            require(tokenId < maxSupply, "Kelteno NFT is Sold Out");
            _tokenIdCounter.increment();
            _mint(to, tokenId);
        }
        baseTokenURI = tokenBaseUrl;
    }

    function mintTo(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "Kelteno NFT is Sold Out");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

     function mintToSender() public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "Kelteno NFT is Sold Out");
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    function mintKelteno(address to) external payable nonReentrant {
        require(keltenoMintingEnabled, "Kelteno Minting is not enabled.");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "Kelteno NFT is Sold Out");
        require(msg.value >= tokenId * keltenoMintValue,string(abi.encodePacked(
                    "Insufficient Payment: Amount of Ether sent is not correct. It should be not less than ",
                    Strings.toString(tokenId * keltenoMintValue)
                )
            )
        );
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function keltenoTokenMintValue() external view returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        return tokenId * keltenoMintValue;
    }

    function privateMint(address to) external payable nonReentrant {
        require(privateMintingEnabled, "Private Minting is not enabled.");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "Kelteno NFT is Sold Out");
        require(
            msg.value >= privateMintPrice,
            string(abi.encodePacked("Insufficient Payment: Amount should be not less than ",Strings.toString(privateMintPrice)))
        );
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /* ---------------------------- @KELTENO SALE -------------------------------*/

    function buyKltnFromDep(uint256 tokenId) external payable nonReentrant {
        require(tokenSellEnabled, "Token Sale Paused");
        require(forSale[tokenId].isExist, "This Token Does not Exist or Not For Sale");
        require(msg.value >= forSale[tokenId].price, string(abi.encodePacked("Insufficient Payment: This Token Costs ", Strings.toString(forSale[tokenId].price))));
        address seller = owner();
        _transfer(seller, msg.sender, tokenId);
        payable(seller).transfer(msg.value);
        _removeTokenAfterSale(tokenId);
    }

    function buyKltnFromContr(uint256 tokenId) external payable nonReentrant {
        require(tokenSellEnabled, "Token Sale Paused");
        require(forSale[tokenId].isExist, "This Token Does not Exist or Not For Sale");
        require(msg.value >= forSale[tokenId].price, string(abi.encodePacked("Insufficient Payment: This Token Costs ", Strings.toString(forSale[tokenId].price))));
        IERC721 NFT = IERC721(address(this));
        NFT.transferFrom(address(this), msg.sender, tokenId);
        _removeTokenAfterSale(tokenId);
    }

    function addTokensForSale(uint256[] memory tokenForSale, uint256 price) external onlyOwner {
        for (uint256 i = 0; i < tokenForSale.length; i++) { 
            forSale[tokenForSale[i]] = TokenForSale(tokenForSale[i],price,true);
            registeredForSale.push(tokenForSale[i]);
        }
    }

    function _removeTokenAfterSale(uint256 tokenForSale) private {
            delete forSale[tokenForSale];
            for(uint256 val = 0; val < registeredForSale.length; val++){
                if(registeredForSale[val] == tokenForSale) {
                    registeredForSale[val] = registeredForSale[registeredForSale.length-1];
                    registeredForSale.pop();
                }
        }
    }

    function removeTokensFromSale(uint256[] memory tokenForSale) external onlyOwner {
        for (uint256 i = 0; i < tokenForSale.length; i++) { 
            delete forSale[tokenForSale[i]];
            for(uint256 val = 0; val < registeredForSale.length; val++){
                if(registeredForSale[val] == tokenForSale[i]) {
                    registeredForSale[val] = registeredForSale[registeredForSale.length-1];
                    registeredForSale.pop();
                }
            }
         }
    }

    function getTokensForSaleQuery() external view returns(uint[] memory, uint[] memory) {
        require(localConfig, 'Local config is not enabled');
        uint256[] memory outputTokenId = new uint256[](registeredForSale.length);
        uint256[] memory outputPrice = new uint256[](registeredForSale.length);
        for(uint i = 0 ; i < registeredForSale.length; i ++) {
            outputTokenId[i] = forSale[registeredForSale[i]].tokenId;
            outputPrice[i] = forSale[registeredForSale[i]].price;
        }
        return (outputTokenId , outputPrice);
    }

    function getTokensForSaleEndpoint() external view returns(uint256[2][] memory ) {
        require(localConfig, 'Local config is not enabled');
        uint256[2][] memory output = new uint256[2][](registeredForSale.length);
        for(uint i = 0 ; i < registeredForSale.length; i ++) {
            output[i] = [
                forSale[registeredForSale[i]].tokenId,
                forSale[registeredForSale[i]].price
            ];
        }
        return output;
    }

    function getTokensForSaleById(uint256 tokenId) external view returns(TokenForSale memory) {
        require(localConfig, 'Local config is not enabled');
        require(forSale[tokenId].isExist, "This token does not Exist or not for Sale");
        return forSale[tokenId];
    }

    /* --------------------- @KELTENO METADATA  ----------------------------*/

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /* --------------------- @KELTENO PAYMENTS AND WITHDRAWALS ------------------*/

    function withdrawPayments(address payable payee) public virtual override onlyOwner {
        super.withdrawPayments(payee);
    }

    function withdrawTo(address payee) external onlyOwner {
        payable(payee).transfer(address(this).balance);
    }

    function transferPayment(address to) external payable onlyOwner {
        payable(to).transfer(msg.value);
    }

    function payMeContract() external payable nonReentrant {
        require(paymentsEnabled,"Payments are not Enabled");
        payable(address(this)).transfer(msg.value);
    }

    function payMeDeployer() external payable nonReentrant {
        require(paymentsEnabled,"Payments are not Enabled");
        payable(owner()).transfer(msg.value);
    }

    /* ---------------------------- @KELTENO AIRDROP -----------------------------------------*/

    function addAirdrops(uint256[] memory _airdrops) external onlyOwner {
        uint256 _nextAirdropId = nextAirdropId;
        for (uint256 i = 0; i < _airdrops.length; i++) {
            airdrops[_nextAirdropId] = _airdrops[i];
            transferFrom(msg.sender, address(this), _airdrops[i]);
            _nextAirdropId++;
        }
    }

    function currentAirDropId() external view returns (uint256) {
        require(localConfig, 'Local config is not enabled');
        return nextAirdropId;
    }

    function airDropPreDeployTokens(address[] calldata lucky) external onlyOwner {
        for (uint256 i = 0; i < lucky.length; i++) {
            mintTo(lucky[i]);
        }
    }

    /* ---------------------------- @KELTENO AIRDROP CLAIM WHITELIST ----------------------------*/

    function addAirDropRecipients(address[] memory _recipients) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) { 
            recipients[_recipients[i]] = true; 
            recipientsRegistry.push(_recipients[i]);
        }
    }

    function removeAirDropRecipients(address[] memory _recipients) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) { 
            _removeAirDropRecepientsFromRegistry(_recipients[i]);
        }
    }

    function _removeAirDropRecepientsFromRegistry(address registeredAddress) private {
         for(uint256 val = 0; val < recipientsRegistry.length; val++){
            if(recipientsRegistry[val] == registeredAddress) {
                recipientsRegistry[val] = recipientsRegistry[recipientsRegistry.length-1];
                recipientsRegistry.pop();
                delete recipients[registeredAddress];
            }
        }
    }

    function getAirdropRecipients() external view returns(address[] memory) {
        require(localConfig, 'Local config is not enabled');
        return recipientsRegistry;
    }

    function claim() external nonReentrant  {
        require(airDropClaimEnabled, 'The airdrop claim is not enabled!');
        require(recipients[msg.sender] == true, "recipient not registered");
        _removeAirDropRecepientsFromRegistry(msg.sender);
        IERC721 NFT = IERC721(address(this));
        NFT.transferFrom(address(this), msg.sender, airdrops[nextAirdropId]);
        nextAirdropId++;
    }

    /**
    * @dev  Release NFTs from contract `onlyOwner`
    * @param NFTAddress address of smart contract
    */
    function releaseContractNFT(address NFTAddress, address receiver, uint256[] memory tokenid) external onlyOwner {
        IERC721 NFT = IERC721(NFTAddress); // Create an instance of the NFT contract
         for(uint256 i = 0; i < tokenid.length; i++){
               NFT.transferFrom(address(this), receiver, tokenid[i]);
         }
    }

    /* ---------------------------- @KELTENO MINTSALE WHITELIST ----------------------------*/

    function addMintRecipients(address[] memory _recipients) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) { 
            mintRecipients[_recipients[i]] = true;
            mintRecipientsRegistry.push(_recipients[i]);
        }
    }

    function removeMintRecipients(address[] memory _recipients) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) { 
            _removeMintRecepientsFromRegistry(_recipients[i]);
        }
    }

    function _removeMintRecepientsFromRegistry(address registeredAddress) private {
         for(uint256 val = 0; val < mintRecipientsRegistry.length; val++){
            if(mintRecipientsRegistry[val] == registeredAddress) {
                mintRecipientsRegistry[val] = mintRecipientsRegistry[mintRecipientsRegistry.length-1];
                mintRecipientsRegistry.pop();
                delete mintRecipients[registeredAddress];
            }
        }
    }

    function getMintClaimRecipients() external view returns(address[] memory) {
        require(localConfig, 'Local config is not enabled');
        return mintRecipientsRegistry;
    }

    function claimMint() external nonReentrant  {
        require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
        require(mintRecipients[msg.sender] == true, "recipient not registered");
        _removeMintRecepientsFromRegistry(msg.sender);
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "Kelteno NFT is Sold Out");
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

}

// ░█─▄▀ ░█▀▀▀ ░█─── ▀▀█▀▀ ░█▀▀▀ ░█▄─░█ ░█▀▀▀█
// ░█▀▄─ ░█▀▀▀ ░█─── ─░█── ░█▀▀▀ ░█░█░█ ░█──░█
// ░█─░█ ░█▄▄▄ ░█▄▄█ ─░█── ░█▄▄▄ ░█──▀█ ░█▄▄▄█
//
//@custom:security-contact chakirberg.s@gmail.com
//
// ▒█▄░▒█ ▒█▀▀▀ ▀▀█▀▀
// ▒█▒█▒█ ▒█▀▀▀ ░▒█░░
// ▒█░░▀█ ▒█░░░ ░▒█░░
//
//@type: [Kelteno][Kelteno]
//
// ▒█▀▀▀ ▒█▀▀█ ▒█▀▀█ ▀▀▀█ █▀█ ▄█░
// ▒█▀▀▀ ▒█▄▄▀ ▒█░░░ ░░█░ ░▄▀ ░█░
// ▒█▄▄▄ ▒█░▒█ ▒█▄▄█ ░▐▌░ █▄▄ ▄█▄