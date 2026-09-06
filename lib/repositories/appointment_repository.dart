import '../models/patient_info.dart';
import '../services/db_service.dart';

abstract class AppointmentRepository {
  List<Appointment> getAppointments();
  void addAppointment(Appointment appointment);
  void updateAppointment(Appointment appointment);
  void deleteAppointment(String id);
}

class LocalAppointmentRepository implements AppointmentRepository {
  @override
  List<Appointment> getAppointments() => DbService().getAppointments();

  @override
  void addAppointment(Appointment appointment) {
    DbService().saveAppointment(appointment);
  }

  @override
  void updateAppointment(Appointment appointment) {
    DbService().saveAppointment(appointment);
  }

  @override
  void deleteAppointment(String id) {
    DbService().deleteAppointment(id);
  }
}
