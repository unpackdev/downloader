// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;


// Importar las librerías necesarias
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";  
// Definir el contrato inteligente de Open Edition
contract MiamiShoeMuseum is ERC1155,Ownable {
    using Strings for uint256;
  
    mapping(uint256 => bool) public balancesNfts;


    bool    priceFixed ; //Flag para indicarr si se cambio de forma extraordinaria
    uint256 countChangePrice = 25; // Cantidad para cambio de precio
    uint256 editionChangePrice = 0.07 ether;  // Precio pos countChangePrice
    uint256 currentId = 0;

    uint256 public editionPrice = 0.12 ether; 
    mapping(uint256 => uint256)  public totalSupply;

    uint256 public maxSupply = 125;
    uint256 public maxCollections = 25;
    string public baseTokenURI;

    address public wallet50a; // Dirección de la primera wallet
    address public wallet50b; // Dirección de la segunda wallet

    // Mapeo para almacenar el saldo de cada edición por dirección
    mapping(uint256 => mapping(address => uint256)) public balances;

    
    constructor(
        string memory _baseTokenURI,
        address _wallet50a,
        address _wallet50b
    ) ERC1155("") {
        baseTokenURI = _baseTokenURI; 
        wallet50a = _wallet50a;
        wallet50b = _wallet50b;
        balancesNfts[currentId] = true;
        priceFixed = true;
      
    }
     
  
    // Función para permitir la compra de ediciones
    function mint(uint256 amount) public payable {
        crossmint(msg.sender,amount); 
    }

    function crossmint(address to, uint256 amount) public payable {
        require(balancesNfts[currentId], 'Venta de NFT Cerrada');
        require(msg.value == editionPrice * amount, 'El valor enviado no coincide con el precio de la edicion');
        require(totalSupply[currentId] + amount <= maxSupply,'Cantidad indisponible');
        

        _mint(to,currentId,amount, "");
        balances[currentId][to]++;  
        
        totalSupply[currentId] += amount;

        if(totalSupply[currentId] == maxSupply){
            balancesNfts[currentId] =  false;
            currentId +=1;
            balancesNfts[currentId] = currentId   < maxCollections;
        }
           
        
        if(priceFixed == true && currentId == 0 && totalSupply[currentId] >= countChangePrice && editionPrice != editionChangePrice)
           editionPrice = editionChangePrice;
         
        // Distribuir las ganancias a las dos wallets
        payable(wallet50a).transfer((msg.value * 50) / 100);
        payable(wallet50b).transfer((msg.value * 50) / 100);
    }
     function setEditionPrice(uint256 newEditionPrice) public onlyOwner {
        editionPrice = newEditionPrice;
        priceFixed = false;
    }

    // Función para configurar la base URI de los metadatos
    function setBaseTokenURI(string memory newBaseTokenURI) public onlyOwner {
        baseTokenURI = newBaseTokenURI;
    }

    // Función para obtener el URI del token
    function uri(uint256 id) public view override returns (string memory) {
        require(totalSupply[id] > 0,"URI: Token Inncorrecto!");
        return string(abi.encodePacked(baseTokenURI, id.toString(),'.json'));
    }

    // Función para consultar el saldo de una edición para una dirección
    function balanceOfEdition(address account,uint256 id) public view returns (uint256) {
        return balances[id][account];
    }
    function getCurrenId() public view returns (uint256) {
        return currentId;
    }

 
}