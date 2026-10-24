#[starknet::interface]
trait IAccessControl<TContractState> {
    fn grant_role(ref self: TContractState, role: felt252, account: ContractAddress);
    fn revoke_role(ref self: TContractState, role: felt252, account: ContractAddress);
    fn has_role(self: @TContractState, role: felt252, account: ContractAddress) -> bool;
}

#[starknet::contract]
mod AccessControl {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry};

    #[storage]
    struct Storage {
        roles: Map<(felt252, ContractAddress), bool>,
        admin: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        RoleGranted: RoleGranted,
        RoleRevoked: RoleRevoked,
    }

    #[derive(Drop, starknet::Event)]
    struct RoleGranted {
        role: felt252,
        account: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct RoleRevoked {
        role: felt252,
        account: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.admin.write(admin);
    }

    #[abi(embed_v0)]
    impl AccessControlImpl of super::IAccessControl<ContractState> {
        fn grant_role(ref self: ContractState, role: felt252, account: ContractAddress) {
            // Strict access control: Only the admin can grant roles
            assert(get_caller_address() == self.admin.read(), 'Unauthorized: Not Admin');
            self.roles.entry((role, account)).write(true);
            self.emit(RoleGranted { role, account });
        }

        fn revoke_role(ref self: ContractState, role: felt252, account: ContractAddress) {
            assert(get_caller_address() == self.admin.read(), 'Unauthorized: Not Admin');
            self.roles.entry((role, account)).write(false);
            self.emit(RoleRevoked { role, account });
        }

        fn has_role(self: @ContractState, role: felt252, account: ContractAddress) -> bool {
            self.roles.entry((role, account)).read()
        }
    }
}
