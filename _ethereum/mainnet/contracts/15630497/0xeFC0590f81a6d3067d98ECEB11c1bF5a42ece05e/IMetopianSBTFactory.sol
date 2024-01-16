pragma solidity >=0.8.0;


interface IMetopianSBTFactory {

    struct TokenType{
        // IPFS CID
        string featuredImageCID;

        // TODO logo image CID 

        string title;
        string space;
        string description;
        string titleEncoded;
        string spaceEncoded;
        string descriptionEncoded;
        string[] fields;

        address owner;
        // address issuer;
        // string issuerName;
    }

    function tokenType(uint id) external view returns(TokenType memory);

}