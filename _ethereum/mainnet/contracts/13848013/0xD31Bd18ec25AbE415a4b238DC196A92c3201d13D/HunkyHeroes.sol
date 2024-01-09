//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ECDSA.sol";


contract HunkyHeroes is ERC721Enumerable, ERC721Burnable {
    uint256 public constant MAX_HEROES = 6500;
    uint256 private constant MINT_MAX = 100;
    uint256 public currentSupply = 0;
    uint256 public mintPrice = 0.02 ether;
    address public msgSigner = address(0x6395d64d6dD3577107c990777e23fEa7D43FC7Df);
    string private baseURI;
    bool public saleLive = false;
    bool public presaleLive = false;
    
    //whitelist tracking
    mapping (address => uint256) public minted;

    //team members
    mapping(address => bool) public teamMap;
    address[3] public teamList;

    //events
    event MembershipTransferred(
        address indexed from, 
        address indexed to
    );

    /**
     * @param baseURI_ is the metadata root for the HunkyHero nfts
     */
    constructor(string memory baseURI_) ERC721("HunkyHeroes", "HERO") {
        teamMap[msg.sender] = true; //Panda as deployer
        teamMap[0x63E600409F305eF517F6f341b69a24d09Fa26B97] = true; //Chief
        teamMap[0x28F5417f0B461cAF68259fFef48Bc098246F1E7c] = true; //Mayor

        teamList[0] = msg.sender; //Panda as deployer
        teamList[1] = 0x63E600409F305eF517F6f341b69a24d09Fa26B97; //Chief
        teamList[2] = 0x28F5417f0B461cAF68259fFef48Bc098246F1E7c; //Mayor

        setBaseURI(baseURI_);
    }

    modifier saleIsLive {
        require(saleLive == true, "Sale is not live");
        _;
    }

    modifier presaleIsLive {
        require(presaleLive == true, "Presale is not live");
        _;
    }

    modifier onlyTeam {
        require(
            teamMap[msg.sender] == true,
            "caller is not on the HunkyHeroes team"
        );
        _;
    }

    /**
     * @notice allow contract to receive Ether
     */
    receive() external payable {}

    //external
    /**
     * @notice list the ids of all the heroes in _owner's wallet
     * @param _owner is the wallet address of the hero owner
     * */
    function listMyHeroes(address _owner) 
        external 
        view 
        returns (uint256[] memory) 
    {
        uint256 nHeroes = balanceOf(_owner);
        // if zero return an empty array
        if (nHeroes == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory heroList = new uint256[](nHeroes);
            uint256 ii;
            for (ii = 0; ii < nHeroes; ii++) {
                heroList[ii] = tokenOfOwnerByIndex(_owner, ii);
            }
            return heroList;
        }
    }

    //public
    /**
     * @notice mint brand new HunkyHero nfts
     * @param numHeroes is the number of heroes to mint
     */
    function mintHero(uint256 numHeroes) public payable saleIsLive {
        require(
            (numHeroes > 0) && (numHeroes <= MINT_MAX),
            "you can mint between 1 and 100 heroes at once"
        );
        require(
            msg.value >= (numHeroes * mintPrice),
            "not enough Ether sent with tx"
        );

        //mint dem heroes
        _mintHeroes(msg.sender, numHeroes);
        return;
    }

    /**
     * @notice mint heroes from the whitelist
     * @param _sig whitelist signature
     * @param _quota wl quota awarded
     * @param _num number of Heroes to mint!
     */
    function herolistMint(
        bytes calldata _sig,
        uint256 _quota,
        uint256 _num
    ) 
        public
        presaleIsLive
    {
        require(_num > 0);

        //overclaiming? already minted?
        require(_num + minted[msg.sender] <= _quota,
            "not enough WL mints left"
        );

        // check msg.sender is on the whitelist
        require(legitSigner(_sig, _quota), "invalid signature");
        
        //effects
        minted[msg.sender] += _num;

        //mint dem heroes
        _mintHeroes(msg.sender, _num);
        return;
    }

    /**
     * @notice burn a hero, perhaps save a civilian
     * @param _heroId the hero to burn
     */
    function ultimateSacrifice(uint256 _heroId) external {
        require(
            _isApprovedOrOwner(msg.sender, _heroId),
            "you can't burn this hero"
        );
        _burn(_heroId);
        //parent contract emits burn event
    }

    //onlyTeam functions
    /**
     * @param newBaseURI will be set as the new baseURI
     * for token metadata access
     */
    function setBaseURI(string memory newBaseURI)
    public
    onlyTeam
    {
        baseURI = newBaseURI;
    }

    /**
     * @notice start or stop minting
     */
    function toggleSale() public onlyTeam {
        saleLive = !saleLive;
    }

    /**
     * @notice start or stop presale minting
     */
    function togglePresale() public onlyTeam {
        presaleLive = !presaleLive;
    }

    /**
     * @notice set a new sale mintPrice in WEI
     * @dev be sure to set the new mintPrice in WEI
     * @param newWeiPrice the new mint mintPrice in WEI
     */
    function setMintPrice(uint256 newWeiPrice) public onlyTeam {
        mintPrice = newWeiPrice;
    }

    /**
    * @notice set a new msgSigner for whitelist validation
    * @param newSigner is the new signer address
    */
    function setMsgSigner(address newSigner) public onlyTeam {
        msgSigner = newSigner;
    }

    /**
     * @notice airdrop heroes for prizes and community perks
     * @param to is the destination address
     * @param num is the number of heroes to airdrop
     */
    function airdropHeroes(address to, uint256 num) public onlyTeam {
        require(num > 0 && num <= MINT_MAX);
        _mintHeroes(to, num);
    }

    /**
     * @notice transfer team membership to a different address
     * team members have admin rights with onlyTeam modifier
     * @param to is the address to transfer admin rights to
     */
    function transferMembership(address to) public onlyTeam {
        teamMap[msg.sender] = false;
        teamMap[to] = true;

        for (uint256 i = 0; i < 3; i++) {
            if (teamList[i] == msg.sender) {
                teamList[i] = to;
            }
        }
        emit MembershipTransferred(msg.sender, to);
    }

    //withdraw to trusted addresses
    function withdraw() public onlyTeam {
        uint256 bal = address(this).balance;

        payable(teamList[0]).send(bal * 2000 / 10000); //Panda
        payable(teamList[1]).send(bal * 4000 / 10000); //Chief
        payable(teamList[2]).send(bal * 4000 / 10000); //Mayor
    }

    //internal
    ///@notice override the _baseURI function in ERC721
    function _baseURI() 
    internal 
    view 
    virtual 
    override 
    returns (string memory) 
    {
        return baseURI;
    }

    //private
    /**
     * @notice mint function called by multiple other functions
     * @notice token IDs start at 1 (not 0)
     * @param _to address to mint to
     * @param _num number of heroes to mint
     */
    function _mintHeroes(address _to, uint256 _num) private {
        require(currentSupply + _num <= MAX_HEROES, "not enough Heroes left");

        for (uint256 h = 0; h < _num; h++) {
            currentSupply ++;
            _safeMint(_to, currentSupply);
        }
    }

    /**
     * @notice does signature _sig contain a legit hash and 
     * was it signed by msgSigner?
     * @param _sig the signature to inspect
     * @dev the signer is recovered and compared to msgSigner
     */
    function legitSigner(bytes memory _sig, uint256 _numHashed)
    private
    view
    returns (bool)
    {
        //hash the sender and this address
        bytes32 checkHash = keccak256(abi.encodePacked(
            msg.sender,
            address(this),
            _numHashed
        ));

        //the _sig should be a signed version of checkHash
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(checkHash);
        address recoveredSigner = ECDSA.recover(ethHash, _sig);
        return (recoveredSigner == msgSigner);
    }

    /**
     * @notice override parent hooks
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) 
        internal
        virtual
        override(ERC721, ERC721Enumerable) 
    {
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
}
