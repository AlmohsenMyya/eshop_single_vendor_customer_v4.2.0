import 'package:eshop/Model/searchAdmin.dart';
import 'package:eshop/repository/adminDetailsRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SearchAdminState {}

class SearchAdminInitial extends SearchAdminState {}

class SearchAdminInProgress extends SearchAdminState {}

class SearchAdminSuccess extends SearchAdminState {
  final List<SearchedAdmin> admins;

  SearchAdminSuccess({required this.admins});
}

class SearchAdminFailure extends SearchAdminState {
  final String errorMessage;

  SearchAdminFailure(this.errorMessage);
}

class SearchAdminCubit extends Cubit<SearchAdminState> {
  final AdminDetailRepository _adminDetailRepository;

  SearchAdminCubit(this._adminDetailRepository) : super(SearchAdminInitial());

  void searchAdmin({required String search}) async {
    emit(SearchAdminInProgress());
    try {
      emit(SearchAdminSuccess(
          admins: await _adminDetailRepository
              .searchAdmin(parameter: {'search': search})));
    } catch (e) {
      emit(SearchAdminFailure(e.toString()));
    }
  }
}
