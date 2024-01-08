// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/*
  ______                                   __                _______                                                                         __    __  ________  ________ 
 /      \                                 /  |              /       \                                                                       /  \  /  |/        |/        |
/$$$$$$  |  ______   __    __   ______   _$$ |_     ______  $$$$$$$  |  ______    ______   _____  ____    ______    ______    _______       $$  \ $$ |$$$$$$$$/ $$$$$$$$/ 
$$ |  $$/  /      \ /  |  /  | /      \ / $$   |   /      \ $$ |__$$ | /      \  /      \ /     \/    \  /      \  /      \  /       |      $$$  \$$ |$$ |__       $$ |   
$$ |      /$$$$$$  |$$ |  $$ |/$$$$$$  |$$$$$$/   /$$$$$$  |$$    $$< /$$$$$$  |/$$$$$$  |$$$$$$ $$$$  |/$$$$$$  |/$$$$$$  |/$$$$$$$/       $$$$  $$ |$$    |      $$ |   
$$ |   __ $$ |  $$/ $$ |  $$ |$$ |  $$ |  $$ | __ $$ |  $$ |$$$$$$$  |$$ |  $$ |$$ |  $$ |$$ | $$ | $$ |$$    $$ |$$ |  $$/ $$      \       $$ $$ $$ |$$$$$/       $$ |   
$$ \__/  |$$ |      $$ \__$$ |$$ |__$$ |  $$ |/  |$$ \__$$ |$$ |__$$ |$$ \__$$ |$$ \__$$ |$$ | $$ | $$ |$$$$$$$$/ $$ |       $$$$$$  |      $$ |$$$$ |$$ |         $$ |   
$$    $$/ $$ |      $$    $$ |$$    $$/   $$  $$/ $$    $$/ $$    $$/ $$    $$/ $$    $$/ $$ | $$ | $$ |$$       |$$ |      /     $$/       $$ | $$$ |$$ |         $$ |   
 $$$$$$/  $$/        $$$$$$$ |$$$$$$$/     $$$$/   $$$$$$/  $$$$$$$/   $$$$$$/   $$$$$$/  $$/  $$/  $$/  $$$$$$$/ $$/       $$$$$$$/        $$/   $$/ $$/          $$/    
                    /  \__$$ |$$ |                                                                                                                                        
                    $$    $$/ $$ |                                                                                                                                        
                     $$$$$$/  $$/        
*/

contract Boomer is ERC721Enumerable, Ownable {
    enum MemberClaimStatus {
        Invalid,
        Listed
    }
    mapping(address => MemberClaimStatus) private _whiteListedMembers;
    mapping(address => uint256) private _whiteListMints;
    using Strings for uint256;
    using SafeMath for uint256;
    string private m_BaseURI = "";
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURIextended;

    // Supply / sale variables
    uint256 public maxBoomers = 10000;
    uint256 public maxBoomerPresalePerAddress = 5;
    uint256 public boomerPrice = 0.069 ether;
    uint256 public maxPerMint = 20;
    uint256 public maxBoomersPerPresaleMint = 5;
    string public baseEst = ".json";

    // Active?!
    bool public mintingActive = false;
    bool public mintingGiveawayActive = false;
    bool public isPresaleActive = false;

    // Provenance
    string public provenanceHash = "";

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        _baseURIextended = _initBaseURI;
    }

    function _setTokenURI(uint256 tokenId) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        string memory uri = tokenURI(tokenId);
        _tokenURIs[tokenId] = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        return string(abi.encodePacked(base, tokenId.toString(), baseEst));
    }

    function mintBoomer(uint256 numberOfBoomers) public payable {
        require(!isPresaleActive, "Presale is active.");
        require(mintingActive, "Minting is not activated yet.");
        require(
            numberOfBoomers > 0,
            "Why are you minting less than zero boomers."
        );
        require(
            totalSupply().add(numberOfBoomers) <= maxBoomers,
            "Only 10,000 Boomers are available"
        );
        require(
            numberOfBoomers <= maxPerMint,
            "Cannot mint this number of boomers in one go !"
        );
        require(
            boomerPrice.mul(numberOfBoomers) <= msg.value,
            "Ethereum sent is not sufficient."
        );
        for (uint256 i = 0; i < numberOfBoomers; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (totalSupply() < maxBoomers) {
                _safeMint(msg.sender, mintIndex);
                _setTokenURI(mintIndex);
            }
        }
    }

    function mintGiveaway(uint256 numberOfBoomers)public payable onlyOwner {
        require(mintingGiveawayActive, "Minting is not activated yet.");
        require(
            totalSupply().add(numberOfBoomers) <= maxBoomers,
            "Only 10,000 Boomers are available"
        );
        for (uint256 i = 0; i < numberOfBoomers; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (totalSupply() < maxBoomers) {
                _safeMint(msg.sender, mintIndex);
                _setTokenURI(mintIndex);
            }
        }
    }

    function mintAsMember(uint256 numberOfBoomers) public payable {
        require(isPresaleActive, "Presale is not active yet.");
        require(numberOfBoomers > 0, "Why are you minting less than zero boomers.");
        require(
            _whiteListedMembers[msg.sender] == MemberClaimStatus.Listed,
            "You are not a whitelisted member !"
        );
        require(
            _whiteListMints[msg.sender].add(numberOfBoomers) <=
                maxBoomerPresalePerAddress,
            "You are minting more than your allowed presale boomers!"
        );
        require(
            totalSupply().add(numberOfBoomers) <= 1000,
            "Only 1,000 boomers are available in presale"
        );
        require(
            numberOfBoomers <= maxBoomersPerPresaleMint,
            "Cannot mint this number of presale boomers in one go !"
        );
        require(
            boomerPrice.mul(numberOfBoomers) <= msg.value,
            "Ethereum sent is not sufficient."
        );

        for (uint256 i = 0; i < numberOfBoomers; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (totalSupply() < maxBoomers) {
                _safeMint(msg.sender, mintIndex);
                _setTokenURI(mintIndex);
                _whiteListMints[msg.sender] = _whiteListMints[msg.sender].add(
                    1
                );
            }
        }
    }

    function addToWhitelist(address[] memory members) public onlyOwner {
        for (uint256 i = 0; i < members.length; i++) {
            _whiteListedMembers[members[i]] = MemberClaimStatus.Listed;
            _whiteListMints[members[i]] = 0;
        }
    }

    function isWhitelisted(address addr) public view returns (bool) {
        return _whiteListedMembers[addr] == MemberClaimStatus.Listed;
    }

    function switchMinting() public onlyOwner {
        mintingActive = !mintingActive;
    }

    function switchMintingGiveaway() public onlyOwner {
        mintingGiveawayActive = !mintingGiveawayActive;
    }

    function switchPresale() public onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function totalBoomers() public view returns (uint256) {
        return totalSupply();
    }

    function setMaxQuantityPerMint(uint256 quantity) public onlyOwner {
        maxPerMint = quantity;
    }

    function setMaxPerPresaleWallet(uint256 quantity) public onlyOwner {
        maxBoomerPresalePerAddress = quantity;
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        provenanceHash = _provenance;
    }

    function withdraw() public payable onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

}
