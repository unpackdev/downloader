// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import "./ERC721URIStorageUpgradeable.sol";
import "./saopay.sol";

contract SaoV1 is ERC721URIStorageUpgradeable, Saopay {
    // token counter
    uint256 public tokenCounter;

    // fee calulator denominator
    uint256 public percentDeno;

    // fee wallet
    address payable feeWallet;


    // struct for storing token details
    struct uriDetails {
        uint256 token_id;
        string uri;
    }

    // mapping token details with struct
    mapping(uint256 => uriDetails) internal dataInfo;

    
    /**
     * @dev Emitted when ETH is transfered.
    */
    event ethTransfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        uint256 artistPayment,
        uint256 artistMargin
    );


    /**
     * @dev Emitted when fee is transfer to fee Wallet.
    */
    event feeTransfer(
        uint256 indexed tokenId, 
        uint256 saoFeeAmount, 
        uint256 saoMargin
    );


    /**
     * @dev Initialized the contract
    */

    function initialize() public initializer {
        __ERC721_init("Serious Art Only", "SAO");
        __Ownable_init(msg.sender);
        tokenCounter = 0;
        percentDeno = 100;
        feeWallet = payable(0xA782423455A7b22f2fe29cbfB1D9EA3a47ceD7DA);
        
    }
 
    // Function part

      /**
     * @dev updates the fee wallet.
     *
     * @param nextOwner new fee wallet address.
     *  
     * Returns
     * - new fee wallet address.
    */

    function updateFeeWallet(address payable nextOwner)
        public
        onlyOwner
        returns (address)
    {
        feeWallet = nextOwner;
        return feeWallet;
    }

      /**
     * @dev updates the denominater.
     *
     * @param _num can be changes to 100 to 1000 if saoMargin is in decimal.
     *
     * Returns
     * - true
    */

    function updateDenominator(uint256 _num)
        public
        onlyOwner
        returns (bool)
    {
        percentDeno = _num;
        return true;
    }

      /**
     * @dev calculates the fee according to saomargin.
     *
     * @param _totalPrice total price of token.
     * @param percentNum saoMargin percentage
     *
     * Returns
     * - fees.
    */

    function feeCalulation(uint256 _totalPrice, uint256 percentNum)
        public
        view
        returns (uint256)
    {
        uint256 fee = percentNum * _totalPrice;
        uint256 fees = fee / percentDeno;
        return fees;
    }

    /**
     * @dev mints the ERC721 NFT tokens.
     *
     * @param _uri URI for token Id.
     *  
     * Returns
     * - token Id.
    */

    function createCollectible(string memory _uri)
        public
        onlyOwner
        returns (uint256 newItemId)
    {
        newItemId = tokenCounter;
        uriDetails storage data = dataInfo[newItemId];
        data.token_id = newItemId;
        data.uri = _uri;
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _uri);
        tokenCounter = tokenCounter + 1;
        return newItemId;
    }

    /**
     * @dev Transfer the ETH funds.
     *
     * @param _amount number of tokens that to be minted.
     * @param receiver receiver address
     * @param _saomargin margin in percentage
     * @param _tokenId token id to be transfered
     *
     * Emits a {feeTransfer} event.
     *
     * Emits a {ethTransfer} event.
    */

    function transferFunds(
        uint256 _amount,
        address payable receiver,
        uint256 _saomargin,
        uint256 _tokenId
        ) public payable onlyOwner 
    {
        uint256 fees = feeCalulation(_amount, _saomargin);
        feeWallet.transfer(fees);
        uint256 artistAmount = _amount - fees;
        uint256 artistMargin = 100 - _saomargin;
        emit feeTransfer(_tokenId, fees, _saomargin);
        receiver.transfer(artistAmount);
        emit ethTransfer(
            msg.sender,
            receiver,
            _tokenId,
            artistAmount,
            artistMargin
        );
    }

    /**
     * @dev Burns the NFT.
     *
     * @param _tokenId token id to be burned.
     *
     * Returns
     * - token Id.
    */

    function deleteNFT(uint _tokenId) 
        public returns(uint256)
    {
        address owner = ownerOf(_tokenId); // internal owner
        require(owner == msg.sender, " You are not owner of token");
        _burn(_tokenId);
        return _tokenId;
    }
}
