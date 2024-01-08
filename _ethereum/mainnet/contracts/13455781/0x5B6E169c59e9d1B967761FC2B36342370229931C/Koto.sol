// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./ECDSA.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Koto is Ownable, ReentrancyGuard, ERC721Enumerable {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32;

    // Public variables
    uint256 public MAX_NFT_SUPPLY = 8888+88;
    uint256 public MAX_PRESALE_NFT_SUPPLY = 222;
    uint256[] public MINT_PRICE = new uint256[](2); // presale, sale
    uint256 public state;
    string public _baseTokenURI;
    uint256 public shiftIndex;
    uint256 private _randomNum = 888;
    string public PROVENANCE;
    address private signerAddress;

    // Team
    address[] private payees;
    mapping(address => uint256) private shares;
    uint256 private totalShares;

    // Events
    event ChangeState(uint256 currentState);
    event Mint(address minter, uint256 quantity);
    event Reveal(uint256 index);

    /**
     * @dev Initialize
     */
    constructor(string memory baseURI, address[] memory _team, uint256[] memory _shares, address _signerAddress) 
        ERC721("The Kotoamatsu Corp", "Koto"){

        // splitter
        require(_team.length == _shares.length, "Payees and shares length mismatch");
        require(_team.length > 0, "No payees");
        for (uint256 i = 0; i < _team.length; i++) {
            addPayee(_team[i], _shares[i]);
        }

        // set url
        setBaseURI(baseURI);

        // mint
        setPresalePrice(688*10**14);
        setMintPrice(888*10**14);

        // signer address
        setSignerAddress(_signerAddress);
    }

    /**
     * @dev Changes signer address. In case of emergency
     */
    function setSignerAddress(address addr) public onlyOwner {
        signerAddress = addr;
    }

    /**
     * @dev Increase supply for WL. The initial plan is 222 -> 444 -> 666 -> 888
     */
    function setPresaleSupply(uint256 newSupply) external onlyOwner {
        require(newSupply < MAX_NFT_SUPPLY, "Cant be > than global supply");
        MAX_PRESALE_NFT_SUPPLY = newSupply;
    }

    /**
     * @dev Gets base url
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Sets base url. In case of emergency
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Sets presale price. In case of emergency
     */
    function setPresalePrice(uint256 _presale) public onlyOwner {
        MINT_PRICE[0] = _presale;
    }

    /**
     * @dev Sets mint price. In case of emergency
     */
    function setMintPrice(uint256 _price) public onlyOwner {
        MINT_PRICE[1] = _price;
    }

    /**
    * @dev Sets state.  0 - sales are paused;  2 - sale
    */
    function setState(uint256 val) external onlyOwner {
       state = val;

       // event
       emit ChangeState(val);
    }

    /**
     * @dev Finalize shift index 
     */
    function reveal() external onlyOwner {
        require(shiftIndex == 0, "Shift index is already set");
        shiftIndex = _randomNum.mod(MAX_NFT_SUPPLY);

        // Prevent default shift index = 0.
        if (shiftIndex == 0) {
            shiftIndex.add(888);
        }

        // event
        emit Reveal(shiftIndex);
    }

    /**
     * @dev Ipfs CID of metas is set
    */
    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        PROVENANCE = provenanceHash;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (shiftIndex != 0){
            if (tokenId < MAX_NFT_SUPPLY){
                uint256 shiftedId = tokenId.add(shiftIndex).mod(MAX_NFT_SUPPLY);
                return string(abi.encodePacked(_baseURI(), shiftedId.toString()));
            } else {
                return string(abi.encodePacked(_baseURI(), tokenId.toString()));
            }

        } else {
            return string(abi.encodePacked(_baseURI(), "not_revealed"));
        }
    }

    /**
    * @dev List NFTs owned by address
    */
    function listNFTs(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /**
    * @dev Recover signer address
    */
    function recoverAddr(address addr, string memory str, bytes memory _signature) public pure returns (address) {
        return keccak256(abi.encode(str, addr)).toEthSignedMessageHash().recover(_signature);
    }

    /**
    * @dev Mints for punlic launch
    */
    function mint(uint256 quantity) external nonReentrant payable {
        require(state == 2, "Sale is paused");
        require(quantity>= 1 && quantity<= 20, "Amount of minted NFTs at once should be in [1,20] interval");
        require(msg.value == MINT_PRICE[1].mul(quantity), "Wrong ETH amount");

        // shiftIndex is only influenced by ordinary mints
        _randomNum = _randomNum.add(uint256(keccak256(abi.encode(blockhash(block.number),
                                                        block.coinbase,
                                                        block.difficulty,
                                                        _msgSender(),
                                                        totalSupply(),
                                                        quantity
                                    ))).mod(MAX_NFT_SUPPLY));

        // mint
        _mintBase(_msgSender(), quantity);

        //
        require(totalSupply() <= MAX_NFT_SUPPLY, "Sale has already ended OR not enough NFTs left");

        // event
        emit Mint(_msgSender(), quantity);
    }

    /**
    * @dev Mints for airdrops
    */
    function mintAirdrop(uint256 quantity, address reciever) external onlyOwner {
        // Just natural limit in case of typo
        require(quantity>= 1 && quantity<= 88, "Amount of minted NFTs at once should be in [1,88] interval");
        _mintBase(reciever, quantity);

        //
        require(totalSupply() <= MAX_NFT_SUPPLY + 8, "Only 8 gods are allowed to be minted");
    }

    /**
    * @dev Mints for presale
    */
    function presaleMint(uint256 quantity, bytes memory _signature) external nonReentrant payable {
        require(state == 1, "Presale is paused");
        require(quantity>= 1, "Amount of minted NFTs should be > 0");
        require(msg.value == MINT_PRICE[0].mul(quantity), "Wrong ETH amount");
        require(signerAddress == recoverAddr(_msgSender(), "presaleMint", _signature), "Not authorized. You need to be whitelisted on Discord");

        // mint
        _mintBase(_msgSender(), quantity);

        // 
        require(balanceOf(_msgSender()) <= 20, "You can presale mint only 20 NFTs in total");

        //
        require(totalSupply() <= MAX_PRESALE_NFT_SUPPLY, "Not all items are available for presale");

        // event
        emit Mint(_msgSender(), quantity);
    }

    /**
    * @dev base mint
    */
    function _mintBase(address to, uint256 quantity) private {
        for (uint i=0; i<quantity; i++){
            
            // mint
            uint256 mintIndex = totalSupply();
            _safeMint(to, mintIndex);
        }
    }

    /**
    * @dev Withdraw ether
    */
    function withdraw() public {
        require(shares[_msgSender()] > 0, "Only team members are allowed");
        // get balance 
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        for (uint256 i = 0; i < payees.length; i++) {
            Address.sendValue(payable(payees[i]), balance.div(totalShares).mul(shares[payees[i]]));
        }
    }

    /**
     * @dev Withdraw ERC20
    */
    function withdrawERC20(address tokenAddress) public {
        require(shares[_msgSender()] > 0, "Only team members are allowed");
        // get balance 
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        for (uint256 i = 0; i < payees.length; i++) {
            IERC20(tokenAddress).transfer(payees[i], balance.div(totalShares).mul(shares[payees[i]]));
        }
    }

    /**
    * @dev Add Payee
    */
    function addPayee(address account, uint256 shares_) private {
        require(account != address(0), "Account is the zero address");
        require(shares_ > 0, "Shares are 0");
        require(shares[account] == 0, "Account already has shares");

        payees.push(account);
        shares[account] = shares_;
        totalShares = totalShares.add(shares_);
    }

    fallback() external payable {
    }
    
    receive() external payable {
    }
}
