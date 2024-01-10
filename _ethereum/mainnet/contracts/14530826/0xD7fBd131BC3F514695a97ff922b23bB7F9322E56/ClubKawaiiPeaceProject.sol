// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";

/*********************************************************************************

                                         #############
                           ####(       ################
                    ,  # ###@#####  .##################
                     # ##################################
                    # #  ##############################
                   .###*  %%#####################%%%#####
                     %%%%%%%############################
                  %%%%%%%%%%%%#########################%%%%%
             %%%%%%%%%%%%%%%%%%%          %        %%%%%%%%%
          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %
    %%%%%%%%%%%%%%%%%%%%%%.%%%%.%%%..%%%%.%%%%%%%%.%%%%%%%%%%%%%%%%%%%%%%%%
     %%%%%%%%%%%%..%%%%%%...........................%%%%%%%%%%%%%%%%%%%%%%
      %%%%%%%%%%%.%%%%%%....  ............... .    ..%%%%%%.%%%%%  %%%%%%
       %%%%%  %%%%%%%%%%.. #@@@ ............. #@@&...%%%%%%.%%%%   %%%%%%%
      %%%%%%%  %%%%%%%%.. ..@@@...............@@@*...%%%%%%%%%%   %%%%%%%%%
     %%%%%%%%%  %%%%%%%... .. ....##%............ ...%%%%%%%%    %%%%%%%%%%
    %%%%%%%%%%    %%%%%%.............................%%%%%%       %%%%%%%%
      %%%%%%%%%    %%%%%%...........................*%%%%%%         %%%%%
       %%%%%%       %%%%%%***...................***%%%%%%          %%%%%
        %%%%%%%        %%%%%%**...............****%%%%%%%          %%%%%%%
       %%%%%%%%%      ////%%********************%%%%//           %%%%%%%%
        %%%%%%%%    ###///////////////****(####(/////////(         %%%%%%
         %%%%%   /#####/////////(//////////****#////////((((        %%%%%%%
       %%%     ######//(((((((((((//////*******///(#####(((((
             //***////#########(((////******#############(/////
            /********##########((////((((**##########/####///////
           ///*******#/#########////((((((((((#######////*****#////

********************************************************************************/

contract ClubKawaiiPeaceProject is ERC1155, Ownable, Pausable, ERC1155Supply {

    using Strings for uint256;

    event Mint( address to, uint256 tokenId, uint256 amount );
    event BatchMint( address to, uint256[] tokenIds, uint256[] amounts );

    string public name;
    string public symbol;
    string public baseURI;
    uint256 public mintPrice;

    // Withdraw addresses
    address public withdrawAddress;

    mapping(uint256 => uint256) private _maxSupply;

    constructor() ERC1155("") {
        name = "Club Kawaii Peace Project";
        symbol = "CKPP";
        baseURI = "https://peaceproject-metadata.clubkawaiinft.com/";
        mintPrice = mintPrice = 0.01 ether;
        withdrawAddress = owner();

        createNewToken(1, 111);
        createNewToken(2, 111);
        createNewToken(3, 111);

        pause();
    }


    function maxSupply(uint256 id_)
    public
    view
    returns (uint256)
    {
        return _maxSupply[id_];
    }

    function setURI(string memory uri_)
    public
    onlyOwner
    {
        _setURI( uri_ );
    }

    function pause()
    public
    onlyOwner
    {
        _pause();
    }

    function unpause()
    public
    onlyOwner
    {
        _unpause();
    }


    function setMintPrice( uint256 newPrice_ )
    public
    onlyOwner
    {
        mintPrice = newPrice_;
    }

    function createNewToken( uint256 tokenId_, uint256 supply_ )
    public
    onlyOwner
    {

        require(
            !exists(tokenId_),
            "Token is already created"
        );

        require(
            supply_ > 0,
            "Supply should be positive"
        );

        _maxSupply[tokenId_] = supply_;

        // mint first one to the owner
        _mint( msg.sender, tokenId_, 1, "");
        emit Mint( msg.sender, tokenId_, 1 );
    }


    function batchCreateNewToken( uint256[] calldata tokenIds_, uint256[] calldata supplies_ )
    public
    onlyOwner
    {

        require(
            tokenIds_.length == supplies_.length,
            "Token IDs and supplies length don't match"
        );

        uint256[] memory amounts = new uint256[]( tokenIds_.length );

        for ( uint256 i = 0;  i < tokenIds_.length; i++ ) {
            require(
                !exists( tokenIds_[i] ),
                "Token is already created"
            );
            require(
                supplies_[i] > 0,
                "Supply should be positive"
            );
            amounts[i] = 1;
            _maxSupply[ tokenIds_[i] ] = supplies_[i];
        }

        // mint first ones to the owner
        _mintBatch( msg.sender, tokenIds_, amounts, "" );
        emit BatchMint( msg.sender, tokenIds_, amounts );
    }


    function setTokenSupply( uint256 tokenId_, uint256 newSupply_ )
    public
    onlyOwner
    {

        require(
            exists(tokenId_),
            "Token doesn't exist"
        );

        require(
            newSupply_ >= totalSupply(tokenId_),
            "New supply must greater or equal to total supply"
        );

        _maxSupply[tokenId_] = newSupply_;

    }

    function batchSetTokenSupply( uint256[] calldata tokenIds_, uint256[] calldata newSupplies_ )
    public
    onlyOwner
    {

        require(
            tokenIds_.length == newSupplies_.length,
            "Token IDs and supplies length don't match"
        );

        for ( uint256 i = 0;  i < tokenIds_.length; i++ ) {
            require(
                exists( tokenIds_[i] ),
                    "Token doesn't exist"
            );
            require(
                newSupplies_[i] > 0,
                "Supply should be positive"
            );
            _maxSupply[ tokenIds_[i] ] = newSupplies_[i];
        }

    }


    function mint( uint256 tokenId_, uint256 amount_ )
    public
    payable
    whenNotPaused
    {

        require(
            exists(tokenId_),
            "Token doesn't exist"
        );

        require(
            totalSupply(tokenId_) + amount_ <= maxSupply(tokenId_),
            "Not enough tokens left"
        );

        uint256 cost = mintPrice * amount_;
        require(
            msg.value >= cost,
            "Payment amount is incorrect"
        );

        _mint( msg.sender, tokenId_, amount_, "" );
        emit Mint( msg.sender, tokenId_, amount_ );

    }

    function batchMint( uint256[] calldata tokenIds_, uint256[] calldata amounts_ )
    public
    payable
    whenNotPaused
    {

        require(
            tokenIds_.length == amounts_.length,
            "Token IDs and amounts length don't match"
        );

        uint256 totalAmount = 0;

        for ( uint256 i = 0;  i < tokenIds_.length; i++ ) {
            require(
                exists( tokenIds_[i] ),
                "Token doesn't exist"
            );
            require(
                totalSupply( tokenIds_[i] ) + amounts_[i] <= maxSupply( tokenIds_[i] ),
                "Not enough tokens left"
            );
            totalAmount += amounts_[i];
        }

        uint256 cost = mintPrice * totalAmount;
        require(
            msg.value == cost,
            "Payment amount is incorrect"
        );

        _mintBatch( msg.sender, tokenIds_, amounts_, "" );
        emit BatchMint( msg.sender, tokenIds_, amounts_ );

    }



    function freeMint( address to_, uint256 tokenId_, uint256 amount_ )
    public
    onlyOwner
    {
        require(
            exists(tokenId_),
            "Token doesn't exist"
        );

        require(
            totalSupply(tokenId_) + amount_ <= maxSupply(tokenId_),
            "Not enough tokens left"
        );

        _mint( to_, tokenId_, amount_, "" );
        emit Mint( to_, tokenId_, amount_ );

    }

    function freeBatchMint( address to_, uint256[] memory tokenIds_, uint256[] memory amounts_ )
    public
    onlyOwner
    {

        require(
            tokenIds_.length == amounts_.length,
            "Token IDs and amounts length don't match"
        );

        for ( uint256 i = 0;  i < tokenIds_.length; i++ ) {
            require(
                exists( tokenIds_[i] ),
                "Token doesn't exist"
            );
            require(
                totalSupply( tokenIds_[i] ) + amounts_[i] <= maxSupply( tokenIds_[i] ),
                "Not enough tokens left"
            );
        }


        _mintBatch( to_, tokenIds_, amounts_, "" );
        emit BatchMint( to_, tokenIds_, amounts_ );

    }


    function setWithdrawAddress( address newAddress ) external onlyOwner {
        withdrawAddress = newAddress;
    }

    function withdrawAmount( uint256 amount ) external onlyOwner {
        require( address(withdrawAddress) != address(0), "withdrawAddress not set" );
        uint256 balance = address(this).balance;
        require( balance > amount - 1, "Insufficent balance" );
        payable( withdrawAddress ).transfer( amount );
    }

    function withdrawAll() external onlyOwner {
        require( address(withdrawAddress) != address(0), "withdrawAddress not set" );
        uint256 balance = address(this).balance;
        require( balance > 0, "Insufficent balance" );
        payable( withdrawAddress ).transfer( balance );
    }


    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    whenNotPaused
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 tokenId)
    override
    public
    view
    returns (string memory)
    {
        require(
            exists(tokenId),
            "Token doesn't exist"
        );
        return string( abi.encodePacked( baseURI, Strings.toString(tokenId) ) );
    }

}
