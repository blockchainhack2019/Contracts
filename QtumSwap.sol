pragma solidity ^0.4.26;


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


contract QtumSwap {

    using SafeMath for uint;

    uint256 SafeTime = 1 hours; //swap timeOut

    struct Swap {
        address participantAddress;
        bytes32 secret;
        bytes20 secretHash;
        uint256 createdAt;
        uint256 balance;
    }

    mapping(address => mapping(address => Swap)) public swaps;

    function createSwap(bytes20 _secretHash, address _participantAddress) public payable {
        require(msg.value > 0);
        require(swaps[msg.sender][_participantAddress].balance == uint256(0));

        swaps[msg.sender][_participantAddress] = Swap(
            _participantAddress,
            bytes32(0),
            _secretHash,
            now,
            msg.value
        );
    }

    function getBalance(address _ownerAddress, address _participantAddress) public view returns (uint256) {
        return swaps[_ownerAddress][_participantAddress].balance;
    }

    function withdraw(bytes32 _secret, address _ownerAddress, address _participantAddress) public {
        Swap memory swap = swaps[_ownerAddress][_participantAddress];

        require(swap.secretHash == ripemd160(_secret));
        require(swap.balance > uint256(0));
        require(swap.createdAt.add(SafeTime) > now);

        swap.participantAddress.transfer(swap.balance);

        swaps[_ownerAddress][_participantAddress].balance = 0;
        swaps[_ownerAddress][_participantAddress].secret = _secret;

    }

    function getSecret(address _ownerAddress, address _participantAddress) public view returns (bytes32) {
        return swaps[_ownerAddress][_participantAddress].secret;
    }

    function refund(address _participantAddress) public {
        Swap memory swap = swaps[msg.sender][_participantAddress];

        require(swap.balance > uint256(0));
        require(swap.createdAt.add(SafeTime) < now);

        msg.sender.transfer(swap.balance);

        clean(msg.sender, _participantAddress);
    }

    function clean(address _ownerAddress, address _participantAddress) internal {
        delete swaps[_ownerAddress][_participantAddress];
    }

}