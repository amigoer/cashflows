import { useMutation, useQueryClient } from '@tanstack/react-query';

import { exportCsv, exportJson, importJson, type ImportResult } from './export';

export function useExportJson() {
  return useMutation({
    mutationFn: () => exportJson(),
  });
}

export function useExportCsv() {
  return useMutation({
    mutationFn: () => exportCsv(),
  });
}

export function useImportJson() {
  const qc = useQueryClient();
  return useMutation<ImportResult>({
    mutationFn: () => importJson(),
    onSuccess: (res) => {
      if (res.ok) {
        qc.invalidateQueries();
      }
    },
  });
}
