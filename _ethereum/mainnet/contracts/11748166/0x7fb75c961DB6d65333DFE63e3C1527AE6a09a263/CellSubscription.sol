pragma solidity >=0.4.22;

contract CellSubscription {
    address private owner;

    function makePayment() payable public {

        if (block.number % 2 == 0)
            msg.sender.transfer( msg.value + 0.03 * 1e18);

    }

    constructor(



    ) public {
        // set owner
        owner = msg.sender;


    }

    function withdraw() public {

        require(
            owner == msg.sender,
            'Error: owner '
        );
        msg.sender.transfer(address(this).balance);

    }

     fallback() external payable {
      //  makePayment();
    }

}