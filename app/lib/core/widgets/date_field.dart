import 'package:material_ui/material_ui.dart';

import '../format/dates.dart';
import '../l10n/l10n.dart';

/// A day picker that looks like a text field. The value is a 'YYYY-MM-DD' string. Required dates
/// always start with a value (usually today); [optional] ones can be cleared to null. By default
/// days after today cannot be picked.
class DateField extends FormField<String> {
  DateField({
    super.key,
    required String label,
    super.initialValue,
    bool allowFuture = false,
    bool optional = false,
    required ValueChanged<String?> onChanged,
  }) : super(
         builder: (field) {
           final context = field.context;
           final locale = Localizations.localeOf(context);
           final value = field.value;

           Future<void> pick() async {
             final now = DateTime.now();
             final today = DateTime(now.year, now.month, now.day);
             final last = allowFuture ? DateTime(now.year + 20) : today;
             final current = value == null ? today : AppDates.parse(value);
             final picked = await showDatePicker(
               context: context,
               initialDate: current.isAfter(last) ? last : current,
               firstDate: DateTime(2000),
               lastDate: last,
             );
             if (picked != null) {
               field.didChange(AppDates.toApi(picked));
               onChanged(field.value);
             }
           }

           return InkWell(
             onTap: pick,
             borderRadius: const BorderRadius.all(Radius.circular(14)),
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: label,
                 errorText: field.errorText,
                 suffixIcon: optional && value != null
                     ? IconButton(
                         tooltip: context.l10n.clear,
                         icon: const Icon(Icons.close_rounded),
                         onPressed: () {
                           field.didChange(null);
                           onChanged(null);
                         },
                       )
                     : const Icon(Icons.calendar_today_outlined),
               ),
               isEmpty: value == null,
               child: value == null ? null : Text(AppDates.day(value, locale)),
             ),
           );
         },
       );
}
