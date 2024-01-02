// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;


// Importar las librerías necesarias
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";  
// Definir el contrato inteligente de Open Edition
contract ToTheMoonEditionV2 is ERC1155,Ownable {
    using Strings for uint256;
  
    uint256 public editionPrice = 0.022 ether; 
    uint256 public totalSupply;

    uint256 public maxSupply = 222;
    string public baseTokenURI;

    address public wallet70; // Dirección de la primera wallet
    address public wallet30; // Dirección de la segunda wallet

    // Mapeo para almacenar el saldo de cada edición por dirección
    mapping(address => uint256) public balances;
    
    constructor(
        string memory _baseTokenURI,
        address _wallet70,
        address _wallet30
    ) ERC1155("") {
        baseTokenURI = _baseTokenURI; 
        wallet70 = _wallet70;
        wallet30 = _wallet30;
      
    }
     
  
    // Función para permitir la compra de ediciones
    function mint(uint256 amount) public payable {
        require(msg.value == editionPrice * amount, 'El valor enviado no coincide con el precio de la edicion');
        require(totalSupply + amount <= maxSupply,'Cantidad indisponible');
        _mint(msg.sender,0,amount, "");
        balances[msg.sender]++;  
        totalSupply += amount;

        // Distribuir las ganancias a las dos wallets
        payable(wallet70).transfer((msg.value * 70) / 100);
        payable(wallet30).transfer((msg.value * 30) / 100);
    }

    function crossmint(address to, uint256 amount) public payable {
        require(msg.value == editionPrice * amount, 'El valor enviado no coincide con el precio de la edicion');
        require(totalSupply + amount <= maxSupply,'Cantidad indisponible');
        _mint(to,0,amount, "");
        balances[to]++;  
        totalSupply += amount;
        
        // Distribuir las ganancias a las dos wallets
        payable(wallet70).transfer((msg.value * 70) / 100);
        payable(wallet30).transfer((msg.value * 30) / 100);
    }
    
    // Función para configurar la base URI de los metadatos
    function setBaseTokenURI(string memory newBaseTokenURI) public onlyOwner {
        baseTokenURI = newBaseTokenURI;
    }

    // Función para obtener el URI del token
    function uri(uint256 id) public view override returns (string memory) {
        require(totalSupply > 0,"URI: Token Inncorrecto!");
        return string(abi.encodePacked(baseTokenURI, id.toString(),'.json'));
    }

    // Función para consultar el saldo de una edición para una dirección
    function balanceOfEdition(address account) public view returns (uint256) {
        return balances[account];
    }
}
