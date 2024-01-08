// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract PodenkNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    
    //---------Variables-------------
    //  Maximo numero de tokens
    uint256 public maxAmntTokens;
    //  Maximo numero de tokens por transaccion
    uint256 public maxTknPerTxs;
    //  Precio de cada NFT
    uint256 public price;
    //  Control de URI
    string newURI;
    //  Control de Collection metadata URI
    string collectionURI;
    //  Controla si la venta esta abierta al publico o no
    bool public saleIsActive = false;
    //  Developer wallet
    address devWallet;
    
    constructor(address _devWallet) ERC721("PODENKS", "PODK") {
        //  Maximo numero de tokens
        maxAmntTokens = 5000;
        //  Maximo numero de tokens por transaccion
        maxTknPerTxs = 20;
        //  Precio de cada NFT
        price = 45000000000000000 wei;
        //  Developer wallet 
        devWallet = _devWallet;
    }
    
    //  Funcion para transferir ganancias del contrato a mi cuenta y a la del socio
    //  95 / 5
    function withdraw() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance.mul(95).div(100));
        payable(devWallet).transfer(address(this).balance);
    }
    
    //  Activar o desactivar la venta
    function flipSaleState() public onlyOwner{
        saleIsActive = !saleIsActive;
    }
    
    //  Reservar NFTs para el owner
    function reservePodenk(uint256 reservedTokens)public onlyOwner{
        require ((reservedTokens.add(checkMintedTokens()) <= maxAmntTokens), "You are minting more NFTs than there are available, mint less tokens!");
        require (reservedTokens <= maxTknPerTxs, "Sorry, the max amount of tokens per transaction is set to 20");
        
        for (uint i=0; i<reservedTokens; i++){
            safeMint(msg.sender);
        }
    }
    
    
    //  Modificar URI
    function setURI(string calldata _newURI) public onlyOwner{
        newURI = _newURI;
    }
    
    //  Modificar URI de coleccion
    function setCollectionURI(string calldata _newCollectionURI) public onlyOwner{
        collectionURI = _newCollectionURI;
    }
    
    //  Metadata del storefront de OpenSea
    function contractURI() public view returns (string memory) {
        return collectionURI;
    }
    
    //  Funcion base de URI de OpenZeppelin
    function _baseURI() internal view override returns (string memory) {
        return newURI;
    }
    
    //  Funcion base de OpenZeppelin
    function safeMint(address to) internal{
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    
    
    //  Checar cuantos tokens han sido minteados
    function checkMintedTokens() public view returns(uint256) {
        return(_tokenIdCounter._value);
    }
    
    //  Recibir pagos directos
    receive() external payable{
        
    }
    
    //  Funcion para mintear los tokens
    function mintPodenk(uint256 amountTokens) public payable {
        //  Requiere que la venta este activa
        require(saleIsActive, "Sale is not active at this moment");
        
        //  Requiere que el numero de tokens que se quieren mintear + el numero de tokens ya minteados
        //  no sobrepase el numero maximo de tokens disponibles del proyecto
        require ((amountTokens.add(checkMintedTokens()) <= maxAmntTokens), "You are minting more NFTs than there are available, mint less tokens!");
        require (amountTokens <= maxTknPerTxs, "Sorry, the max amount of tokens per transaction is set to 20");
        
        //  Requiere que la cantidad de ETH enviada sea la correcta
        require (msg.value == (price.mul(amountTokens)), "Amount of Ether incorrect, try again.");
        
        
        //  Iteramos la cantidad de veces necesaria para mintear los NFTs del cliente y los minteamos en cada iteracion
        for (uint i=0; i<amountTokens; i++){
            safeMint(msg.sender);
        }
    }
}