pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";

//  :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//  :::::'###::::'########::'########:'########::'#######:::::'###::::'########::'########:
//  ::::'## ##::: ##.... ##: ##.....::... ##..::'##.... ##:::'## ##::: ##.... ##:..... ##::
//  :::'##:. ##:: ##:::: ##: ##:::::::::: ##:::: ##:::: ##::'##:. ##:: ##:::: ##::::: ##:::
//  ::'##:::. ##: ########:: ######:::::: ##:::: ##:::: ##:'##:::. ##: ##:::: ##:::: ##::::
//  :: #########: ##.....::: ##...::::::: ##:::: ##:::: ##: #########: ##:::: ##::: ##:::::
//  :: ##.... ##: ##:::::::: ##:::::::::: ##:::: ##:::: ##: ##.... ##: ##:::: ##:: ##::::::
//  :: ##:::: ##: ##:::::::: ########:::: ##::::. #######:: ##:::: ##: ########:: ########:
//  ::..:::::..::..:::::::::........:::::..::::::.......:::..:::::..::........:::........::

// ApeToadz are a product of Koper mad scientist with the dream of taking over the metaverse, he collected
// the dna of cryptoadz and intersected it with kong an legendary ape warrior. the experiment succeeded, with
// one exception the apetoaz are rebellious in nature and koper lost his life in an effort to control them,
// only another ape can control an apetoadz. now roaming without control in the laboratory of koper they have
// unveiled the truth about their creation and are in known about the current state of the metaverse, bound
// to their roots they decided to take the side of toadz. with the battle still going strong against gremplin.
// Help is needed to assure victory. help the apetoadz to escape from koper laboratory by choosing how many
// to free during minting.

// find out more on apetoadz.com

contract ApeToadzFarm is ERC721Enumerable, Ownable {

    using Strings for uint256;

    // boolean
    bool public isMintOpen = false;

    //uint256s
    uint256 MAX_SUPPLY = 6669;
    uint256 FREE_MINTS = 369;
    uint256 PRICE = .069 ether;
    uint256 MAX_MINT_PER_TX = 20;

    // strings
    string private _baseURIExtended;

    //events
    event TokenMinted(uint256 supply);

    constructor() ERC721("ApeToadz", "APETOADZ") { }

    function _baseMint(address _to, uint _count, bool _isFreeMint) internal {
        uint _totalSupply = totalSupply();
        uint num_tokens = _count;
        if ((num_tokens + _totalSupply) > MAX_SUPPLY) {
            num_tokens = MAX_SUPPLY - _totalSupply;
        }

        for (uint i=0; i < num_tokens; i++) {
            _safeMint(_to, _totalSupply);
            emit TokenMinted(_totalSupply);

            if (_isFreeMint) {
                // say it loud we minted free ones!
                for (uint j=0; j < 5; j++) {
                    emit Transfer(address(0), _to, _totalSupply);
                }
            }

            _totalSupply = _totalSupply + 1;
        }
    }

    function mint(address _to, uint _count) public payable {
        require(isMintOpen, "Mint not yet opened!");
        require(_count <= MAX_MINT_PER_TX, "Max mint per transaction exceeded");

        uint _totalSupply = totalSupply();
        bool isFreeMint = false;
        if (_totalSupply > FREE_MINTS) {
            require(PRICE*_count <= msg.value, 'Not enough ether sent (check PRICE variable for eth to send for each Toadz)');
        } else isFreeMint = true;

        require(_totalSupply < MAX_SUPPLY, 'Max supply already reached');
        _baseMint(_to, _count, isFreeMint);
    }

    function burn(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);
        _transfer( msg.sender, 0x000000000000000000000000000000000000dEaD, _tokenId);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function getNFTsByOwner(address _wallet) public view returns (uint256[] memory) {
        uint256 numOfTokens = balanceOf(_wallet);
        uint256[] memory tokensId = new uint256[](numOfTokens);
        for (uint256 i; i < numOfTokens; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function ownerMint(address[] memory recipients, uint256[] memory amount) external onlyOwner {
        require(recipients.length == amount.length, 'Arrays needs to be of equal lenght');
        uint256 totalToMint = 0;
        for (uint256 i=0; i<amount.length; i++) {
            totalToMint = totalToMint + amount[i];
        }
        require((totalSupply() + totalToMint) <= MAX_SUPPLY, 'Mint will exceed total supply');

        for (uint256 i=0; i<recipients.length; i++) {
            _baseMint(recipients[i], amount[i], false);
        }
    }

    function setMintOpen(bool _isMintOpen) public onlyOwner {
        isMintOpen = _isMintOpen;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        PRICE = _newPrice;
    }

    function setFreeMint(uint256 _freeMint) public onlyOwner {
        FREE_MINTS = _freeMint;
    }

}