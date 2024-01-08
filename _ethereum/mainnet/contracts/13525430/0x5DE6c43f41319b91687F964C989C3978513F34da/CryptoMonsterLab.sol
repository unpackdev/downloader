// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./console.sol";

/**
 * @title CryptoMonster Lab ERC-721 Smart Contract
 */

 //    _____ ________   _______ _____ ________  ________ _   _  _____ _____ ___________     _       ___  ______ 
 //   /  __ \| ___ \ \ / / ___ \_   _|  _  |  \/  |  _  | \ | |/  ___|_   _|  ___| ___ \   | |     / _ \ | ___ \
 //   | /  \/| |_/ /\ V /| |_/ / | | | | | | .  . | | | |  \| |\ `--.  | | | |__ | |_/ /   | |    / /_\ \| |_/ /
 //   | |    |    /  \ / |  __/  | | | | | | |\/| | | | | . ` | `--. \ | | |  __||    /    | |    |  _  || ___ \
 //   | \__/\| |\ \  | | | |     | | \ \_/ / |  | \ \_/ / |\  |/\__/ / | | | |___| |\ \    | |____| | | || |_/ /
 //    \____/\_| \_| \_/ \_|     \_/  \___/\_|  |_/\___/\_| \_/\____/  \_/ \____/\_| \_|   \_____/\_| |_/\____/ 

 //                                                            .:
 //                                                           / )
 //                                                          ( (
 //                                                           \ )
 //           o                                             ._(/_.
 //            o                                            |___%|
 //          ___              ___  ___  ___  ___             | %|
 //          | |        ._____|_|__|_|__|_|__|_|_____.       | %|
 //          | |        |__________________________|%|       | %|
 //          |o|          | | |%|  | |  | |  |~| | |        .|_%|.
 //         .' '.         | | |%|  | |  |~|  |#| | |        | ()%|
 //        /  o  \        | | :%:  :~:  : :  :#: | |     .__|___%|__.
 //       :____o__:     ._|_|_."    "    "    "._|_|_.   |      ___%|_
 //       '._____.'     |___|%|                |___|%|   |_____(____  )
 //                                                                 ( (
 //                                                                  \ '._____.-
 //                                                                   '._______.-
 //   from the mind of Santiago Uceda 2021
 //   team: dropacid.eth 0xSam Level23 CML Community
 //   thanks to all the token holders for your support

abstract contract BoredApeYachtClub {
   function balanceOf(address owner) external virtual view returns (uint256 balance);
}

abstract contract CollectionContract {
   function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract CryptoMonsterLab is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {

    string public CRYPTOMONSTER_PROVENANCE = "";
    uint256 public constant TOKEN_PRICE = 80000000000000000; // 0.08 ETH
    uint256 public constant MAX_TOKENS_PURCHASE = 20;
    uint256 public constant RESERVED_TOKENS = 20;
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public numTokensMinted = 0;
    bool public mintIsActive = false;

    string private baseURI;

    // WALLET BASED PRESALE
    uint256 public constant PRESALE_TOKEN_PRICE = 60000000000000000; // 0.06 ETH
    uint256 public constant MAX_TOKENS_PURCHASE_PRESALE = 5;
    bool public presaleIsActive = false;
    mapping (address => bool) public presaleWalletList;

    // DISCORD PRESALE
    uint256 public constant DISCORD_PRESALE_TOKEN_PRICE = 60000000000000000; // 0.06ETH
    uint256 public constant MAX_TOKENS_PURCHASE_DISCORD_PRESALE = 5;
    uint256 public constant MAX_DISCORD_PRESALE_TOKENS = 5000;
    uint256 public discordPresaleNumTokensMinted = 0;
    bool public discordPresaleIsActive = false;
    mapping (address => bool) public discordPresaleWalletsMinted;

    // BAYC PRESALE
    BoredApeYachtClub private bayc = BoredApeYachtClub(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
    BoredApeYachtClub private mayc = BoredApeYachtClub(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);
    uint256 public constant MAX_BAYC_TOKENS = 2000;
    uint256 public constant MAX_TOKENS_PURCHASE_BAYC = 5;
    uint256 public baycPresaleNumTokenMinted = 0;
    bool public baycPresaleIsActive = false;
    mapping (address => bool) public baycWalletsMinted;

    // NFT COLLECTIONS PRESALE
    CollectionContract private ethercards = CollectionContract(0x97CA7FE0b0288f5EB85F386FeD876618FB9b8Ab8);
    CollectionContract private ethereans = CollectionContract(0xfd3fd9b793bAc60e7F0a9b9fB759DB3e250383cB);
    CollectionContract private animetas = CollectionContract(0x18Df6C571F6fE9283B87f910E41dc5c8b77b7da5);
    CollectionContract private wickedCraniums = CollectionContract(0x85f740958906b317de6ed79663012859067E745B);
    CollectionContract private deadheads = CollectionContract(0x6fC355D4e0EE44b292E50878F49798ff755A5bbC);

    uint256 public constant COLLECTION_TOKEN_PRICE = 70000000000000000; // 0.07ETH
    uint256 public constant MAX_COLLECTION_PRESALE_TOKENS = 5000;
    uint256 public constant MAX_TOKENS_PURCHASE_COLLECTION_PRESALE = 5;
    uint256 public collectionPresaleNumTokenMinted = 0;
    bool public collectionPresaleIsActive = false;
    mapping (address => bool) public collectionWalletsMinted;


    constructor() ERC721("CryptoMonsters", "CML") {}

    function reserveTokens() external onlyOwner {
        uint256 mintIndex = numTokensMinted;
        for (uint256 i = 0; i < RESERVED_TOKENS; i++) {
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex + i);
        }
    }

    // PUBLIC MINT
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function mintCryptoMonster(uint256 numberOfTokens) external payable nonReentrant{
        require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
        require(mintIsActive, "Mint is not active.");
        require(numberOfTokens <= MAX_TOKENS_PURCHASE, "You went over max tokens per transaction.");
        require(numTokensMinted + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            if (numTokensMinted < MAX_TOKENS) {
                numTokensMinted++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    // WALLET BASED PRESALE
    function flipPresaleState() external onlyOwner {
	    presaleIsActive = !presaleIsActive;
    }

    function initPresaleWalletList(address[] memory walletList) external onlyOwner {
	    for (uint i; i < walletList.length; i++) {
		    presaleWalletList[walletList[i]] = true;
	    }
    }

    function mintPresale(uint256 numberOfTokens) external payable nonReentrant{
        require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
	    require(presaleIsActive, "Presale is not active");
	    require(presaleWalletList[msg.sender] == true, "You are not on the presale wallet list or have already minted");
	    require(numberOfTokens <= MAX_TOKENS_PURCHASE_PRESALE, "You went over max tokens per transaction.");
	    require(numTokensMinted + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");
	    require(PRESALE_TOKEN_PRICE * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH.");

	    for (uint256 i = 0; i < numberOfTokens; i++) {
		    uint256 mintIndex = numTokensMinted;
		    if (numTokensMinted < MAX_TOKENS) {
			    numTokensMinted++;
			    _safeMint(msg.sender, mintIndex);
		    }
	    }
	    presaleWalletList[msg.sender] = false;
    }

    // DISCORD PRESALE MINT
    function flipDiscordPresaleMintState() external onlyOwner {
        discordPresaleIsActive = !discordPresaleIsActive;
    }

    function mintDiscordPresaleToken(uint256 numberOfTokens) external payable nonReentrant{
        require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
        require(discordPresaleIsActive, "Mint is not active.");
        require(discordPresaleWalletsMinted[msg.sender] == false, "You have already minted!");
        require(numberOfTokens <= MAX_TOKENS_PURCHASE_DISCORD_PRESALE, "You went over max tokens per transaction.");
	    require(numTokensMinted + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");
	    require(discordPresaleNumTokensMinted + numberOfTokens <= MAX_DISCORD_PRESALE_TOKENS, "Discord Presale is over");
        require(DISCORD_PRESALE_TOKEN_PRICE * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
		    uint256 mintIndex = numTokensMinted;
		    if (numTokensMinted < MAX_TOKENS) {
			    numTokensMinted++;
                discordPresaleNumTokensMinted++;
			    _safeMint(msg.sender, mintIndex);
		    }
	    }

        discordPresaleWalletsMinted[msg.sender] = true;
    }

    // BAYC PRESALE
    function flipBAYCPresaleMintState() external onlyOwner {
        baycPresaleIsActive = !baycPresaleIsActive;
    }

    function numBAYCOwned(address _owner) external view returns (uint256) {
        return bayc.balanceOf(_owner);
    }

    function mintBAYCPresale(uint256 numberOfTokens) external payable nonReentrant{
        require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
        require(baycPresaleIsActive, "BAYC Mint is not active.");
        require(bayc.balanceOf(msg.sender) > 0 || mayc.balanceOf(msg.sender) > 0, "You are not a member of BAYC, WTF!");
        require(baycWalletsMinted[msg.sender] == false, "You have already minted!");
        require(numberOfTokens <= MAX_TOKENS_PURCHASE_BAYC, "You went over max tokens per transaction.");
	    require(numTokensMinted + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");
	    require(baycPresaleNumTokenMinted + numberOfTokens <= MAX_BAYC_TOKENS, "BAYC Presale is over");
        require(COLLECTION_TOKEN_PRICE * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
		    uint256 mintIndex = numTokensMinted;
		    if (numTokensMinted < MAX_TOKENS) {
			    numTokensMinted++;
                baycPresaleNumTokenMinted++;
			    _safeMint(msg.sender, mintIndex);
		    }
	    }

        baycWalletsMinted[msg.sender] = true;
    }

    // NFT COLLECTION PRESALE
    function flipCollectionPresaleMintState() external onlyOwner {
        collectionPresaleIsActive = !collectionPresaleIsActive;
    }

    function qualifyForCollectionPresaleMint(address _owner) external view returns (bool) {
        return ethereans.balanceOf(_owner) > 0 || ethercards.balanceOf(_owner) > 0 || 
            animetas.balanceOf(_owner) > 0 || deadheads.balanceOf(_owner) > 0 || 
            wickedCraniums.balanceOf(_owner) > 0;
    }

    function mintCollectionPresale(uint256 numberOfTokens) external payable nonReentrant{
        require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
        require(collectionPresaleIsActive, "NFT Collection Mint is not active.");
        require(collectionWalletsMinted[msg.sender] == false, "You have already minted!");
        require(
            ethereans.balanceOf(msg.sender) > 0 || ethercards.balanceOf(msg.sender) > 0 || 
            animetas.balanceOf(msg.sender) > 0 || deadheads.balanceOf(msg.sender) > 0 || 
            wickedCraniums.balanceOf(msg.sender) > 0, 
            "You are not a member of Ethereans, Ethercards, Animetas, DeadHeads or Wicked Craniums!"
        );
        require(
            numberOfTokens <= MAX_TOKENS_PURCHASE_COLLECTION_PRESALE,
            "You went over max tokens per transaction."
        );
	    require(numTokensMinted + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");
	    require(
            collectionPresaleNumTokenMinted + numberOfTokens <= MAX_COLLECTION_PRESALE_TOKENS, 
            "Collection Presale is over"
        );
        require(COLLECTION_TOKEN_PRICE * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
		    uint256 mintIndex = numTokensMinted;
		    if (numTokensMinted < MAX_TOKENS) {
			    numTokensMinted++;
                collectionPresaleNumTokenMinted++;
			    _safeMint(msg.sender, mintIndex);
		    }
	    }

        collectionWalletsMinted[msg.sender] = true;
    }

    // burn the bad cryptomonster
    function burn(uint256 tokenId) public virtual {
	    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
	    _burn(tokenId);
    }

    // OWNER FUNCTIONS
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        CRYPTOMONSTER_PROVENANCE = provenanceHash;
    }

    function setPaused(bool _setPaused) public onlyOwner {
	    return (_setPaused) ? _pause() : _unpause();
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    // Toggle this function if pausing should suspend transfers
    function _beforeTokenTransfer(
	    address from,
	    address to,
	    uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
	    require(!paused(), "Pausable: paused");
	    super._beforeTokenTransfer(from, to, tokenId);
    }
}
