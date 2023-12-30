// SPDX-License-Identifier: UNLICENSED
/**
 * @dev Credits to
 * Mathieu L. @ ProApps 
 * https://proapps.fr
 * september 7th 2020 
 *
 * @dev Property
 * all rights are reserved to ArtCertificate
 *
 * @dev Deployed successfully with compilers :
 *      - 0.5.17
 */
pragma solidity >=0.4.22 <0.8.0;



/**
* @title SafeMath
* @dev Unsigned math operations with safety checks that revert on error
* @dev source : openzeppelin-solidity/contracts/math/SafeMath.sol
*/
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


/**
* Utility library of inline functions on addresses
* @dev source : openzeppelin-solidity/contracts/utils/Address.sol
*/
library Address {
    /**
    * Returns whether the target address is a contract
    * @dev This function will return false if invoked during the constructor of a contract,
    * as the code is not actually created until after the constructor finishes.
    * @param account address of the account to check
    * @return whether the target address is a contract
    */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be     
        // contracts then.  /* 9 sept. 2020 : checked */
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
* @title IERC165
* @dev https://eips.ethereum.org/EIPS/eip-165
* @dev source : openzeppelin-solidity/contracts/introspection/IERC165.sol
*/
interface IERC165 {
    /**
    * @notice Query if a contract implements an interface
    * @param interfaceId The interface identifier, as specified in ERC-165
    * @dev Interface identification is specified in ERC-165. This function
    * uses less than 30,000 gas.
    */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


/**
* @title ERC165
* @author Matt Condon (@shrugs)
* @dev Implements ERC165 using a lookup table.
* @dev source : openzeppelin-solidity/contracts/introspection/ERC165.sol
* @dev NB: The only interface registered by this all contract is the ERC165 interface itself ( 0x01ffc9a7 )
*/
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    /*
    * 0x01ffc9a7 ===
    *     bytes4(keccak256('supportsInterface(bytes4)'))
    */

    /**
    * @dev a mapping of interface id to whether or not it's supported
    */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
    * @dev A contract implementing SupportsInterfaceWithLookup
    * implement ERC165 itself
    */
    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
    * @dev implement supportsInterface(bytes4) using a lookup table
    */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
    * @dev internal method for registering an interface
    */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
* @dev source : openzeppelin-solidity/contracts/ownership/Ownable.sol
*/
contract Ownable {
    address private _owner = address(0x9eb10fE7C86f301aa7E5F6446BF4301D12aaC0e2);
    address internal ZERO_ADDRESS = address(0);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor () internal {
        // give contract ownership to contract deployer
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
    * @return the address of the owner.
    */
    function proprietaire_contrat() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
    * @return true if `msg.sender` is the owner of the contract.
    */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

   
    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
* @title CertificateStructures
* @dev `Certificate` and `Artwork` structs definitions 
*/
contract CertificateStructures {
    /* Certificate Schemas */
    // metadatas of the certificate
    struct Certificate {
        uint id;                    // to add on creation
        uint date_certificat;       // to add on creation
        address eth_adresse_proprietaire;
        string identifiant_unique_non_consecutif;
        string url_image_externe;
        string url_certificat;
    }
  
    // metadatas of the artwork
    struct Artwork {
        uint date_oeuvre;
        string deposant;
        string artiste;
        string signature;
        string numero_serie;
        string oeuvre;
        string support;
        string dimension;
    }
}


/**
* @title ArtCertificate NFT Assets
* @dev NON-STANDARD contract
* @dev Each certificate id MUST lead to :
{
    identifiant_unique_non_consecutif,          
    deposant,
    artiste,
    oeuvre,
    date_oeuvre,
    support,
    dimension,
    signature,
    numero_serie,
    eth_adresse_proprietaire
}
*/
contract ArtCertificate is Ownable, CertificateStructures, ERC165 {
    using SafeMath for uint256;

    event CertificateTransferred(uint certificateId, address _from, address _to);

    /*--------------------------------------------------STORAGE---------------------------------------------------*/
    // available id for next certificate
    uint256 public nextCertificateId = 1; 

    /* Public Storage */
    string public site_web = "https://www.artcertificate.eu/";
    string public constant nom = "Artcertificate";
    string public constant symbole = "ART";

    // Certificates storage
    mapping(uint256 => Certificate) public certificates;
    // Artworks storage
    mapping(uint256 => Artwork) public artworks;
    // All Certificates
    uint[] private certificateIds;
    // Mapping certificate owner => certificateIds
    mapping(address => uint256[]) private ownedCertificates;


    /*--------------------------------------------------ACCESS RESTRICTIONS---------------------------------------------------*/
    modifier onlyCertificateOrContractOwner(uint _id) {
        require(
            isOwner()
            || proprietaireCertificat(_id) == msg.sender
        );
        _;
    }

    
    /*-------------------------------------------------SETTER FUNCTIONS----------------------------------------------------*/
    function print(
        uint date_oeuvre,
        string memory identifiant_unique_non_consecutif,          
        string memory deposant,
        string memory artiste,
        string memory oeuvre,
        string memory support,
        string memory dimension,
        string memory signature,
        string memory numero_serie,
        string memory url_image_externe,
        string memory url_certificat
    ) public onlyOwner returns (uint){

        Certificate memory certificate;
        Artwork memory artwork;

        // add all certificate's params
        certificate = Certificate(
            nextCertificateId,
            block.timestamp,
            proprietaire_contrat(),
            identifiant_unique_non_consecutif,
            url_image_externe,
            url_certificat
        );

        // add all artwork's params
        artwork = Artwork(
            date_oeuvre,      
            deposant,
            artiste,
            signature,
            numero_serie,
            oeuvre,
            support,
            dimension
        );
        
        // add new certificate to certificates
        certificates[nextCertificateId] = certificate; 
        
        // add new artwork to artworks
        artworks[nextCertificateId] = artwork;

        // store certificate id to certificateIds
        certificateIds.push(nextCertificateId);

        // add owner to ownedCertificates
        ownedCertificates[proprietaire_contrat()].push(nextCertificateId);
        
        // add 1 to next certificate available id    
        nextCertificateId = nextCertificateId.add(1);

        return nextCertificateId.sub(1);

    }

    /**
    * @dev Website url setter
    * @dev access restricted to contract owner only
    * @param _url the new url to set as the url of the website
    */
    function setWebsiteUrl(string memory _url) public onlyOwner {
        site_web = _url;
    }
    
    /**
    * @dev Transfer a certificate
    * @dev access restricted to certificate or contract owner only
    * @param _id the id of the certificate to transfer ownership of
    * @param _newOwner the ethereum public address of the new certificate owner (will be denied if _newOwner is a contract)
    */
    function transferer_certificat(uint _id, address _newOwner) public onlyCertificateOrContractOwner(_id) {
        require(_newOwner != ZERO_ADDRESS);
        require(!Address.isContract(_newOwner));

        // retrieve certificate
        Certificate memory certificate = certificates[_id];
        // retrieve old owner
        address oldOwner = certificate.eth_adresse_proprietaire;
        // give Certificate ownership 
        certificates[_id].eth_adresse_proprietaire = _newOwner;
        // add to certificate owners (ownedCertificates)
        ownedCertificates[_newOwner].push(_id);
        // take certificate owner off from ownedCertificates
        for (uint i = 0; i < ownedCertificates[oldOwner].length; i++) {
            if (ownedCertificates[oldOwner][i] == _id) {
                delete ownedCertificates[oldOwner][i];
            }
        }

        emit CertificateTransferred(_id, oldOwner, _newOwner);


        
    }


    /*-------------------------------------------------GETTER FUNCTIONS----------------------------------------------------*/
    
    /**
    * @dev Returns owner's certificates
    * @param _proprietaire ethereum public address of the certificate owner
    * @return certificats_proprietaire : the certificates of `_proprietaire`
    */
    function certificatsProprietaire(address _proprietaire) public view returns(uint[] memory) {
        return ownedCertificates[_proprietaire];
    }

    /**
    * @dev Returns caller's certificates
    * @return mes_certificats
    */
    function mesCertificats() public view returns(uint[] memory mes_certificats) {
        return certificatsProprietaire(msg.sender);
    }

    /**
    * @dev Returns certificate's owner by id
    * @param _id the id of the certificate to retrieve owner of
    * @return proprietaire_certificat : the owner of certificate with `_id`
    */
    function proprietaireCertificat(uint _id) public view returns(address proprietaire_certificat) {
        return certificates[_id].eth_adresse_proprietaire;
    }

    /**
    * @dev Returns an external url leading to certificate's image 
    * @param _id the id of the certificate to retrieve image of
    * @return lien_vers_image : url pointing to an image of the certificate with `_id`
    */
    function imageCertificat(uint _id) public view returns(string memory lien_vers_image) {
        return certificates[_id].url_image_externe;
    }

    function liste_certificats() public view returns(uint[] memory) {
        return certificateIds;
    }
}
/* end */